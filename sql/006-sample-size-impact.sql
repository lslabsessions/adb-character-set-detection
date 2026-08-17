/*
	Compare a complete sample with a truncated 60-byte sample.

	The Windows-1252-specific characters are deliberately placed later in the
	text. With sample_size = 60, DETECT_CHARSET does not see them.

	This script also demonstrates that:
	* a reasonable score does not guarantee exact detection;
	* DBMS_LOB conversion can return warning = 0 even when the wrong source
	  character set was selected;
	* VALIDATE_CHARACTER_ENCODING can return 0 for text that is structurally
	  valid but semantically incorrect
*/

set serveroutput on;

declare
    l_result         utl_i18n.charset_result_table;

    l_blob           blob;
    l_clob           clob;
    l_raw            raw(32767);

    l_text           varchar2(4000);

    procedure run_test(
        p_label       in varchar2,
        p_sample_size in pls_integer
    ) is
        l_detected_cs  varchar2(100);
        l_score        number;
        l_dest_offset  integer := 1;
        l_src_offset   integer := 1;
        l_lang_context integer := dbms_lob.default_lang_ctx;
        l_warning      integer;
        l_validation   pls_integer;
    begin
        utl_i18n.detect_charset(
            result      => l_result,
            src         => l_blob,
            profile     => 1,
            num_results => 10,
            sample_size => p_sample_size
        );

        if not l_result.exists(1) then
            raise_application_error(
                -20001,
                'No character set candidate returned.'
            );
        end if;

        l_detected_cs := l_result(1).charset;
        l_score       := l_result(1).score;

        dbms_lob.createtemporary(l_clob, true);

        dbms_lob.converttoclob(
            dest_lob     => l_clob,
            src_blob     => l_blob,
            amount       => dbms_lob.lobmaxsize,
            dest_offset  => l_dest_offset,
            src_offset   => l_src_offset,
            blob_csid    => nls_charset_id(l_detected_cs),
            lang_context => l_lang_context,
            warning      => l_warning
        );

        l_validation :=
            utl_i18n.validate_character_encoding(l_clob);

        dbms_output.put_line('=== ' || p_label || ' ===');
        dbms_output.put_line(
            'Detected charset   : ' || l_detected_cs
        );
        dbms_output.put_line(
            'Detection score    : ' || l_score
        );
        dbms_output.put_line(
            'Converted text     : ' ||
            dbms_lob.substr(l_clob, 4000, 1)
        );
        dbms_output.put_line(
            'Conversion warning : ' || l_warning
        );
        dbms_output.put_line(
            'Validation result  : ' || l_validation
        );
        dbms_output.put_line('');

        if dbms_lob.istemporary(l_clob) = 1 then
            dbms_lob.freetemporary(l_clob);
        end if;

    exception
        when others then
            if dbms_lob.istemporary(l_clob) = 1 then
                dbms_lob.freetemporary(l_clob);
            end if;
            raise;
    end run_test;

begin
    l_text :=
        'João and José visited Guimarães and stopped for café before returning to Lisbon. ' ||
        'After dinner João paid €25 — “That’s expensive”, José said.';

    l_raw := utl_i18n.string_to_raw(
        l_text,
        'WE8MSWIN1252'
    );

    dbms_lob.createtemporary(l_blob, true);

    dbms_lob.writeappend(
        l_blob,
        utl_raw.length(l_raw),
        l_raw
    );

    -- NULL means that the full input length is analyzed.
    run_test(
        'FULL SAMPLE',
        null
    );

    -- Only the first 60 bytes are analyzed.
    run_test(
        'SAMPLE_SIZE = 60',
        60
    );

    if dbms_lob.istemporary(l_blob) = 1 then
        dbms_lob.freetemporary(l_blob);
    end if;

exception
    when others then
        if dbms_lob.istemporary(l_clob) = 1 then
            dbms_lob.freetemporary(l_clob);
        end if;

        if dbms_lob.istemporary(l_blob) = 1 then
            dbms_lob.freetemporary(l_blob);
        end if;

        raise;
end;
/

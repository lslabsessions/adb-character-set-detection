/*
 Main lab pipeline:

   external bytes
       -> DETECT_CHARSET of the source character set
       -> most likely Oracle character set
       -> NLS_CHARSET_ID
       -> DBMS_LOB.CONVERTTOCLOB
       -> CLOB in the database character set
       -> VALIDATE_CHARACTER_ENCODING
       -> DETECT_CHARSET of the converted character set

 The source is generated as WE8MSWIN1252 only to create deterministic lab
 data. In a real integration, l_blob would normally contain the original
 bytes received from a file, API, message, or legacy application
*/

set serveroutput on;

declare
    l_result         utl_i18n.charset_result_table;

    l_blob           blob;
    l_clob           clob;
    l_raw            raw(32767);

    l_text           varchar2(4000);
    l_detected_cs    varchar2(100);
    l_score          number;

    l_dest_offset    integer := 1;
    l_src_offset     integer := 1;
    l_lang_context   integer := dbms_lob.default_lang_ctx;
    l_warning        integer;
    l_validation     pls_integer;
begin
    l_text :=
        'João paid €25 — “That’s expensive”, José said.';

    ------------------------------------------------------------
    -- 1. Simulate an external Windows-1252 source
    ------------------------------------------------------------
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

    ------------------------------------------------------------
    -- 2. Detect the source character set
    ------------------------------------------------------------
    utl_i18n.detect_charset(
        result      => l_result,
        src         => l_blob,
        profile     => 1,
        num_results => 10
    );

    if not l_result.exists(1) then
        raise_application_error(
            -20001,
            'No character set candidate returned.'
        );
    end if;

    l_detected_cs := l_result(1).charset;
    l_score       := l_result(1).score;

    dbms_output.put_line(
        'Detected charset   : ' || l_detected_cs
    );

    dbms_output.put_line(
        'Detection score    : ' || l_score
    );

    ------------------------------------------------------------
    -- 3. Convert the source bytes into the database character set
	--
	-- blob_csid identifies the character set of the source BLOB.
	-- The destination CLOB uses the database character set
	-- (AL32UTF8 in this lab), so no destination charset needs
	-- to be specified explicitly
    ------------------------------------------------------------
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

    dbms_output.put_line(
        'Converted text     : ' ||
        dbms_lob.substr(l_clob, 4000, 1)
    );

    dbms_output.put_line(
        'Conversion warning : ' || l_warning
    );

    ------------------------------------------------------------
    -- 4. Validate the resulting character data
    ------------------------------------------------------------
    l_validation :=
        utl_i18n.validate_character_encoding(l_clob);

    dbms_output.put_line(
        'Validation result  : ' || l_validation
    );


    utl_i18n.detect_charset(
        result      => l_result,
        src         => l_clob,
        profile     => 1,
        num_results => 10
    );

    if not l_result.exists(1) then
        raise_application_error(
            -20001,
            'No character set candidate returned.'
        );
    end if;

    l_detected_cs := l_result(1).charset;
    l_score       := l_result(1).score;

    dbms_output.put_line(
        'Detected charset in the converted text  : ' || l_detected_cs
    );

    dbms_output.put_line(
        'Detection score    : ' || l_score
    );


    ------------------------------------------------------------
    -- 5. Cleanup
    ------------------------------------------------------------
    if dbms_lob.istemporary(l_clob) = 1 then
        dbms_lob.freetemporary(l_clob);
    end if;

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
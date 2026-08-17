/*
	Demonstrate that detection quality depends on the bytes present in the
	sample, not only on the true source character set

	Both samples are encoded as WE8MSWIN1252:
	
	Sample 1 contains characters that are also represented identically in WE8ISO8859P1
	
	Sample 2 adds Windows-1252 discriminating characters such as the euro sign, typographic quotes, apostrophe, and em dash
*/

set serveroutput on;

declare
    procedure detect_sample(
        p_label in varchar2,
        p_text  in varchar2
    ) is
        l_result utl_i18n.charset_result_table;
        l_blob   blob;
        l_raw    raw(32767);
    begin
        l_raw := utl_i18n.string_to_raw(
            p_text,
            'WE8MSWIN1252'
        );

        dbms_lob.createtemporary(l_blob, true);

        dbms_lob.writeappend(
            l_blob,
            utl_raw.length(l_raw),
            l_raw
        );

        utl_i18n.detect_charset(
            result      => l_result,
            src         => l_blob,
            profile     => 1,
            num_results => 10
        );

        dbms_output.put_line('=== ' || p_label || ' ===');
        dbms_output.put_line('Source encoding : WE8MSWIN1252');
        dbms_output.put_line('Text            : ' || p_text);
        dbms_output.put_line('Top candidate   : ' || l_result(1).charset);
        dbms_output.put_line('Top score       : ' || l_result(1).score);
        dbms_output.put_line('');

        if dbms_lob.istemporary(l_blob) = 1 then
            dbms_lob.freetemporary(l_blob);
        end if;

    exception
        when others then
            if dbms_lob.istemporary(l_blob) = 1 then
                dbms_lob.freetemporary(l_blob);
            end if;
            raise;
    end detect_sample;

begin
    detect_sample(
        'AMBIGUOUS SAMPLE',
        'João and José visited Guimarães and stopped for café before returning to Lisbon.'
    );

    detect_sample(
        'DISCRIMINATING SAMPLE',
        'João paid €25 — “That’s expensive”, José said.'
    );
end;
/

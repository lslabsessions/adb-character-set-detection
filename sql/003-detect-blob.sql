/*
	Build a controlled Windows-1252 byte stream and detect its character set.
	
	STRING_TO_RAW is used only to generate deterministic lab data. In a real
	integration, the BLOB/BFILE would normally contain the bytes received from
	the external system or file.
*/

set serveroutput on;

declare
    l_result utl_i18n.charset_result_table;
    l_blob   blob;
    l_raw    raw(32767);
    l_text   varchar2(4000);
begin
    l_text :=
        'João paid €25 — “That’s expensive”, José said.';

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

    utl_i18n.detect_charset(
        result      => l_result,
        src         => l_blob,
        profile     => 1,
        num_results => 10
    );

    for i in 1 .. l_result.count loop
        dbms_output.put_line(
            rpad(l_result(i).charset, 30) ||
            ' Score: ' ||
            l_result(i).score
        );
    end loop;

    if dbms_lob.istemporary(l_blob) = 1 then
        dbms_lob.freetemporary(l_blob);
    end if;

exception
    when others then
        if dbms_lob.istemporary(l_blob) = 1 then
            dbms_lob.freetemporary(l_blob);
        end if;
        raise;
end;
/

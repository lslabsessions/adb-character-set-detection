/*  02-detect-varchar2.sql
	Baseline detection using VARCHAR2.

	In the test database NLS_CHARACTERSET = AL32UTF8. This is useful as a
	baseline, but external encoding detection is better demonstrated using the
	original byte stream (for example BLOB/BFILE) before those bytes have been
	interpreted as database character data.*/

set serveroutput on;

declare
    l_result utl_i18n.charset_result_table;
    l_text   varchar2(4000);
begin
    l_text :=
        'João and José visited Guimarães and stopped for café before returning to Lisbon.';

    utl_i18n.detect_charset(
        result      => l_result,
        src         => l_text,
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
end;
/

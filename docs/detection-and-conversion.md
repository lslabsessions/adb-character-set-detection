# Detection and Conversion Pipeline

This document explains the mechanics of the main PL/SQL workflow. It does not repeat the sampling experiment or the byte-level comparison between Windows-1252 and ISO-8859-1.

## 1. Preserve the incoming byte stream

A real integration may receive data from a file, API, message, legacy application, or another external source.

If the encoding is not already trustworthy, the safest input for detection is the original byte stream rather than text that has already been decoded.

The lab uses a `BLOB` for this reason.

## 2. Creating deterministic lab data

The scripts use:

```plsql
utl_i18n.string_to_raw(
    l_text,
    'WE8MSWIN1252'
);
```

only to manufacture a known byte stream for testing.

This is **not** the intended production flow. In a real integration, the BLOB would normally already contain the bytes received from the source.

## 3. Detect the likely source character set

The central call is:

```plsql
utl_i18n.detect_charset(
    result      => l_result,
    src         => l_blob,
    profile     => 1,
    num_results => 10
);
```

The result is a ranked `CHARSET_RESULT_TABLE`.

The lab selects the first candidate:

```plsql
l_detected_cs := l_result(1).charset;
l_score       := l_result(1).score;
```

Production code should also decide how to handle cases where no candidate is returned or where the result is too ambiguous for automatic processing.

## 4. Convert the bytes into the database character set

The detected Oracle character-set name is converted to a character-set ID:

```plsql
nls_charset_id(l_detected_cs)
```

The BLOB is then converted into a CLOB:

```plsql
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
```

For `DBMS_LOB.CONVERTTOCLOB`, `blob_csid` identifies the **character set of the source BLOB bytes**.

The destination CLOB contains database character data. In the lab environment, `NLS_CHARACTERSET = AL32UTF8`.

## 5. Why `AL32UTF8 -> AL32UTF8` is still valid in this pipeline

If the source BLOB is already encoded as `AL32UTF8`, the same generic flow can still be used.

There is no need for a special branch solely because the source and database character sets match: the application still needs to turn a byte-oriented BLOB into character-oriented CLOB data, and `CONVERTTOCLOB` can perform that operation using `AL32UTF8` as `blob_csid`.

## 6. Conversion in the opposite direction

For outbound integrations, `DBMS_LOB.CONVERTTOBLOB` performs the inverse type of operation:

```text
CLOB in database character set
        |
        v
DBMS_LOB.CONVERTTOBLOB
        |
        v
BLOB encoded in the requested character set
```

For `CONVERTTOBLOB`, `blob_csid` identifies the **character set to use for the destination BLOB bytes**.

This gives a useful symmetry:

```text
CONVERTTOCLOB: blob_csid = source BLOB encoding
CONVERTTOBLOB: blob_csid = destination BLOB encoding
```

## 7. Conversion warnings

`DBMS_LOB.CONVERTTOCLOB` returns a warning value when an inconvertible source character is encountered.

However, `warning = 0` does not prove that the source character set was correctly identified. Oracle can successfully convert bytes according to a wrong source assumption and still produce structurally valid destination text.

The concrete demonstration of this behavior is documented in [`sample-size-and-confidence.md`](sample-size-and-confidence.md).

## 8. Validate the resulting character data

After conversion, the lab runs:

```plsql
utl_i18n.validate_character_encoding(l_clob)
```

A result of `0` means that the CLOB is valid character data for the applicable Oracle character set.

This is a structural check, not a business-content or source-preservation check. See [`concepts.md`](concepts.md) for that distinction.

## Practical pipeline

```text
retain source bytes
      |
      v
detect likely charset
      |
      v
evaluate candidate / score / context
      |
      v
convert to database character data
      |
      v
check conversion warning
      |
      v
validate character encoding
      |
      v
apply application/domain checks where required
```

## References

- Oracle AI Database 26ai — `UTL_I18N`  
  https://docs.oracle.com/en/database/oracle/oracle-database/26/arpls/UTL_I18N.html
- Oracle AI Database 26ai — `DBMS_LOB`  
  https://docs.oracle.com/en/database/oracle/oracle-database/26/arpls/DBMS_LOB.html

# Character Set Detection and Conversion in Oracle AI Database 26ai

This hands-on lab explores native character set detection in Oracle AI Database 26ai using `UTL_I18N.DETECT_CHARSET`, and builds a practical detection, conversion, and validation workflow around it.

The lab goes beyond simply calling the new API. It examines how the content and size of a data sample affect detection accuracy, how externally encoded byte streams can be converted into the database character set, why structurally valid character data does not necessarily mean that the original text was preserved correctly, and what to consider when moving from legacy single-byte character sets to `AL32UTF8`.

## Why this matters

Character encoding problems commonly surface in three situations:

1. **Migrations** — for example, moving applications and data from a database using a legacy single-byte character set such as `WE8MSWIN1252` to a Unicode database using `AL32UTF8`.
2. **Integrations** — applications may receive files and payloads from heterogeneous sources through FTP/SFTP, file shares, object storage, web services, REST/SOAP APIs, messaging systems, or legacy applications. Those sources are not always homogeneous and may use different, incorrect, or undocumented character encodings.
3. **Web input** — text handled by browsers and web applications can also have encoding problems. For example, a web page or API response may declare UTF-8 while actually containing Windows-1252 bytes, invalid byte sequences may be received, or valid Unicode text entered by a user may later be sent to a legacy system that cannot represent all of its characters.

If the source encoding is unknown or incorrectly assumed, characters such as:

- `€`
- `—`
- `“ ”`
- `’`
- `ã`
- `é`

may be corrupted, replaced, or interpreted incorrectly.

Oracle AI Database 26ai introduces three new `UTL_I18N` procedures:

- `DETECT_CHARSET`
- `DETECT_LANGUAGE`
- `DETECT_LANGUAGE_CHARSET`

This lab focuses on `DETECT_CHARSET` and its use in a practical character-set detection and conversion pipeline.

## Character set, encoding, "ANSI", and UTF-8

A **character set** describes the repertoire of characters that can be represented, while a **character encoding** describes how those characters are represented as bytes. In Oracle terminology, names such as `AL32UTF8`, `WE8MSWIN1252`, and `WE8ISO8859P1` are called character sets, even though they also determine the byte representation used by the database.

The names encountered most often in this lab are:

```text
AL32UTF8       -> Oracle character set for standard UTF-8
WE8MSWIN1252   -> Windows-1252 / CP1252
WE8ISO8859P1   -> ISO-8859-1 / Latin-1
```

Windows-1252 is frequently referred to informally as **"ANSI"** in Western Windows environments. `ANSI` is not, however, the name of one universal encoding: other Windows regions historically used different code pages. ISO-8859-1 is also a different encoding and should not simply be called ANSI.

Legacy single-byte encodings such as Windows-1252 were efficient and practical when applications mainly needed one regional repertoire. Windows-1252 represents Portuguese and other Western European languages well, but it cannot represent many characters used in Japanese, Arabic, Greek, Chinese, emoji, and other Unicode ranges.

UTF-8 became the preferred choice for modern systems because one encoding can represent the Unicode repertoire, allowing text from many languages and writing systems to coexist without switching regional code pages. ASCII characters still use one byte in UTF-8, while other characters use additional bytes as required.

The detailed discussion, including byte examples and the distinction between invalid byte sequences and characters that are not representable in a target character set, is available in [`docs/concepts.md`](docs/concepts.md).

## What the lab covers

- Checking the database and national character sets
- Detecting a character set from `VARCHAR2`
- Detecting a character set from the original byte stream in a `BLOB`
- Comparing ambiguous and discriminating Windows-1252 samples
- Detecting and converting external bytes into the database character set
- Relating encoding problems to integration payloads and browser/web input
- Understanding the effect of `sample_size`
- Using `VALIDATE_CHARACTER_ENCODING`
- Showing why valid encoding does not necessarily mean that the original text was preserved correctly
- Comparing `BYTE` and `CHAR` length semantics for `AL32UTF8`
- Documenting version observations from Oracle AI Database 26ai
- Comparing the native PL/SQL API with a previous Java GDK approach

## Main flow

```text
External / legacy bytes
        |
        v
       BLOB
        |
        v
UTL_I18N.DETECT_CHARSET
        |
        v
Ranked character-set candidates
+ likelihood scores
        |
        v
Select highest-ranked candidate
        |
        v
NLS_CHARSET_ID()
        |
        v
DBMS_LOB.CONVERTTOCLOB
        |
        v
CLOB in the database character set
(AL32UTF8 in this lab)
        |
        v
UTL_I18N.VALIDATE_CHARACTER_ENCODING
```

## Test environment

The functional lab was tested on:

```text
Oracle AI Database 26ai Enterprise Edition
Release 23.26.3.1.0 - Production
Version 23.26.3.1.0
```

Database globalization settings:

```text
NLS_CHARACTERSET        AL32UTF8
NLS_NCHAR_CHARACTERSET  AL16UTF16
```

## Key findings

### 1. Detection is probabilistic

`UTL_I18N.DETECT_CHARSET` returns a list of possible Oracle character sets ranked by likelihood, together with their scores. When this lab needs one detected character set for the conversion workflow, it selects the first row — the highest-ranked candidate.

That choice is a practical interpretation of the result, not proof of the source encoding. The score is useful for comparing candidates, but the first candidate is still only the detector's strongest hypothesis for the bytes and sample that were analyzed.

### 2. Closely related character sets can be difficult to distinguish

Oracle documents `WE8MSWIN1252` as a **single-byte binary superset** of `WE8ISO8859P1`.

This relationship is important for character-set detection. Ordinary Western European characters such as:

```text
ã  é  ç  á  ó  ü  ñ
```

do not provide strong evidence for distinguishing Windows-1252 from ISO-8859-1 because they are represented with the same byte values in both character sets.

A `WE8MSWIN1252` byte stream containing only characters from this common repertoire:

```text
João and José visited Guimarães and stopped for café before returning to Lisbon.
```

was detected in the test environment as:

```text
WE8ISO8859P1  Score: 0.694688
```

This is not necessarily evidence that the detector "failed". The sample did not contain strong byte-level evidence that required Windows-1252.

Windows-1252 becomes easier to distinguish when the sample contains characters assigned in the `0x80`–`0x9F` byte range.

The 27 graphic characters defined by Windows-1252 in that range are:

```text
€  ‚  ƒ  „  …  †  ‡  ˆ  ‰  Š  ‹  Œ  Ž
‘  ’  “  ”  •  –  —  ˜  ™  š  ›  œ  ž  Ÿ
```

The five Windows-1252 byte positions `0x81`, `0x8D`, `0x8F`, `0x90`, and `0x9D` are undefined.

ISO-8859-1 uses the `0x80`–`0x9F` range for C1 control characters rather than these Windows-1252 graphic characters.

The second test therefore used:

```text
João paid €25 — “That’s expensive”, José said.
```

It contains several strong Windows-1252 discriminators:

```text
€  —  “  ”  ’
```

The result changed to:

```text
WE8MSWIN1252  Score: 0.797947
```

The exact source character set may therefore be difficult to distinguish when the byte stream contains only the common portion of closely related encodings.

A detailed byte-by-byte comparison is available in [`docs/concepts.md`](docs/concepts.md).

### 3. UTF-8 was clearly identified

In this lab, `AL32UTF8` is the Oracle character set used for standard UTF-8. The same discriminating text encoded as `AL32UTF8` was detected as:

```text
AL32UTF8  Score: 0.980853
```

The visible text was identical to the Windows-1252 sample, but its byte representation was different. This illustrates why character-set detection is fundamentally about the underlying byte stream, not only about the characters displayed by a client.

### 4. Sample size can materially affect detection

A longer `WE8MSWIN1252` sample was tested twice.

With only the first 60 bytes analyzed:

```text
Detected charset   : WE8ISO8859P1
Detection score    : 0.704489
Converted text     : ... paid ?25 ? ?That?s expensive? ...
Conversion warning : 0
Validation result  : 0
```

With the complete sample:

```text
Detected charset   : WE8MSWIN1252
Detection score    : 0.721792
Converted text     : ... paid €25 — “That’s expensive” ...
Conversion warning : 0
Validation result  : 0
```

The characters that distinguish Windows-1252 occurred later in the input. Restricting `sample_size` excluded those discriminating bytes.

The default `sample_size => NULL` uses the full input length. For large inputs, sampling may reduce the amount of data analyzed, but it must be treated as an accuracy/performance trade-off rather than as a default optimization.

### 5. Successful conversion does not prove that detection was correct

When the truncated sample identified `WE8ISO8859P1`, `DBMS_LOB.CONVERTTOCLOB` completed with `warning = 0`, even though the text was interpreted incorrectly.

A conversion warning reports conversion problems such as an inconvertible source character. It does not verify that the supplied source character set was the correct one.

### 6. Valid encoding does not mean that the original text was preserved correctly

`UTL_I18N.VALIDATE_CHARACTER_ENCODING` returned `0` for both the correctly converted and incorrectly interpreted CLOBs.

For example:

```text
?25 ? ?That?s expensive?
```

contains valid `AL32UTF8` characters. The function can therefore report that the resulting encoding is structurally valid even though the original:

```text
€25 — “That’s expensive”
```

was not preserved.

Encoding validation checks whether character data is valid for the relevant character set. It does not know what characters the source system originally intended.

### 7. Preserve original bytes when recovery matters

Character-set detection can only use information that is still present in the byte stream. Once an earlier lossy conversion has replaced a character, later detection cannot reconstruct the lost information.

For integration pipelines where recovery or reprocessing may be necessary, retaining the original bytes can therefore be valuable.

## Lab scripts

Run the scripts in numerical order:

| Script | Purpose |
|---|---|
| `001-environment-and-version.sql` | Check version, character sets, and API presence |
| `002-detect-varchar2.sql` | Establish a `VARCHAR2` baseline |
| `003-detect-blob.sql` | Detect a controlled Windows-1252 byte stream |
| `003-detect-blob-al32utf8.sql` | Detect a controlled AL32UTF8 byte stream |
| `004-ambiguous-vs-discriminating.sql` | Compare ambiguous and discriminating samples |
| `005-detect-and-convert.sql` | Run the main detect → convert → validate pipeline |
| `006-sample-size-impact.sql` | Demonstrate the risk of truncated sampling |
| `007-validate-character-encoding.sql` | Demonstrate structural encoding validation |
| `008-length-semantics.sql` | Explore `BYTE` vs `CHAR` semantics in `AL32UTF8` |

## Supporting notes

- [`docs/concepts.md`](docs/concepts.md)
- [`docs/detection-and-conversion.md`](docs/detection-and-conversion.md)
- [`docs/sample-size-and-confidence.md`](docs/sample-size-and-confidence.md)
- [`docs/migration-considerations.md`](docs/migration-considerations.md)
- [`docs/legacy-java-gdk.md`](docs/legacy-java-gdk.md)

## Legacy background

A previous on-premises solution used the Oracle Globalization Development Kit Java API and `oracle.i18n.lcsd.LCSDetector`, exposed to PL/SQL through a Java stored procedure.

In that implementation, character data was materialized into a temporary BLOB before being passed to the Java detector. That added deployment and runtime complexity around Java classes, the PL/SQL-to-Java bridge, and temporary LOB management.

Oracle AI Database 26ai exposes character-set detection directly through `UTL_I18N.DETECT_CHARSET`.

See [`docs/legacy-java-gdk.md`](docs/legacy-java-gdk.md).

## Migration consideration: BYTE vs CHAR semantics

A migration from a single-byte character set such as `WE8MSWIN1252` to `AL32UTF8` may expose column-length assumptions that were previously invisible.

For example:

```text
Desassociação
```

contains 13 characters but occupies 15 bytes in UTF-8.

Therefore these definitions are not equivalent in an `AL32UTF8` database:

```sql
VARCHAR2(13 BYTE)
VARCHAR2(13 CHAR)
```

See [`docs/migration-considerations.md`](docs/migration-considerations.md).

## Important conclusion

The core detection and conversion flow is:

```text
detect -> convert
```

For a production integration, a safer workflow adds source context, byte preservation, result evaluation, and validation around those two core operations.

1. **Understand the source and any declared encoding**  
   Check what is already known about the incoming data before relying on detection. A partner specification may define an encoding, an HTTP `Content-Type` may declare one, or the source system may have a known character set. Detection should be considered together with this information rather than automatically replacing it.

2. **Preserve the original bytes when appropriate**  
   If the source encoding is unknown or not trustworthy, retain the original byte stream before decoding it as text. This can be done, for example, by keeping external data in a `BLOB`. Decoding with the wrong assumptions can produce mojibake or a lossy conversion and may destroy information that would otherwise help identify the original encoding.

3. **Detect the most likely character set**  
   Run `UTL_I18N.DETECT_CHARSET` on the available data. The procedure returns ranked character-set candidates together with scores. When this lab requires a single result, it selects the first candidate, which is the detector's highest-ranked hypothesis.

4. **Evaluate the detection result and the sample quality**  
   Do not treat the first candidate as absolute proof. Consider the score, alternative candidates, and whether the analyzed sample contains bytes that meaningfully distinguish the possible encodings. A sample containing only characters shared by Windows-1252 and ISO-8859-1 may remain ambiguous, while characters such as `€`, `—`, `“`, and `”` provide stronger distinguishing evidence.

5. **Convert using the selected source character set**  
   Once a source character set has been selected, use it to interpret and convert the original bytes. In this lab, `NLS_CHARSET_ID` resolves the Oracle character-set identifier and `DBMS_LOB.CONVERTTOCLOB` converts the source `BLOB` into database character data.

6. **Validate the structural character encoding**  
   Use `UTL_I18N.VALIDATE_CHARACTER_ENCODING` to check whether the resulting character data is structurally valid for its Oracle character set. Structural validity does not prove that the original text was preserved correctly. A replacement such as `?`, for example, can itself be a perfectly valid character.

7. **Apply application or domain checks when preserving the intended text matters**  
   Where the exact intended content is important, apply checks that understand the expected data. Structural encoding validation cannot determine that `?25` was originally intended to be `€25`, so business rules, expected formats, or other source-specific knowledge may still be required.

## References

- Oracle AI Database 26ai — `UTL_I18N`  
  https://docs.oracle.com/en/database/oracle/oracle-database/26/arpls/UTL_I18N.html
- Oracle AI Database 26ai — Changes in This Release  
  https://docs.oracle.com/en/database/oracle/oracle-database/26/arpls/release-changes.html
- Oracle AI Database 26ai — `DBMS_LOB`  
  https://docs.oracle.com/en/database/oracle/oracle-database/26/arpls/DBMS_LOB.html
- Oracle Database Migration Assistant for Unicode Guide — Oracle documents `WE8MSWIN1252` as a single-byte binary superset of `WE8ISO8859P1`  
  https://docs.oracle.com/pls/topic/lookup?ctx=en/database/oracle/oracle-database/18/nlspg&id=DUMAG-GUID-3CA04A80-4870-469F-9FBB-0578779E7622
- Unicode Consortium — Windows CP1252 mapping table  
  https://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1252.TXT

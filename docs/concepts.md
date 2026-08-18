# Core Concepts

## Text is characters to us, but bytes to systems

When we read text such as:

```text
João paid €25.
```

we think in terms of characters:

```text
J  o  ã  o     €  2  5
```

A computer, however, ultimately stores and transmits bytes.

The same visible character can therefore have different byte representations depending on the character encoding being used.

For example, the euro sign `€` can be represented as:

```text
WE8MSWIN1252  -> 80
AL32UTF8      -> E2 82 AC
```

The visible character is the same.

The underlying bytes are not.

This distinction is fundamental when receiving text from files, browsers, APIs, message queues, legacy applications, object storage, or other external systems.

## Character set vs character encoding

The terms **character set** and **character encoding** are closely related, and in practice they are sometimes used interchangeably, but conceptually they describe different things.

A **character set** defines the repertoire of characters that can be represented.

A **character encoding** defines how those characters are represented as bytes.

Conceptually:

```text
Characters
    |
    v
Character set
    |
    v
Character encoding
    |
    v
Bytes
```

Unicode is a useful example.

Unicode assigns each character a unique numerical value called a code point.

For example:

```text
€ -> U+20AC
ã -> U+00E3
😀 -> U+1F600
```

Those code points can then be encoded into bytes using an encoding such as UTF-8.

For example:

```text
Character   Unicode     UTF-8 bytes
---------   --------    -----------
A           U+0041      41
ã           U+00E3      C3 A3
€           U+20AC      E2 82 AC
😀          U+1F600     F0 9F 98 80
```

This means that the character and its byte representation are not the same concept.

## Oracle terminology

Oracle uses the term **character set** for identifiers such as:

```text
AL32UTF8
WE8MSWIN1252
WE8ISO8859P1
```

In practice, an Oracle character set identifies both:

- the repertoire of characters that can be represented;
- the encoding rules used to represent those characters as bytes.

For this reason, Oracle APIs use terminology such as:

```text
UTL_I18N.DETECT_CHARSET
```

even though the detection process is fundamentally examining byte patterns and determining which character set/encoding most likely explains them.

This document follows Oracle terminology where appropriate while still distinguishing the underlying concepts.

## UTF-8 and "ANSI"

Two terms frequently encountered in applications and integrations are:

```text
UTF-8
ANSI
```

They are not equivalent concepts.

### UTF-8

UTF-8 is a Unicode character encoding.

In Oracle Database, the normal character set corresponding to standard UTF-8 is:

```text
AL32UTF8
```

`AL32UTF8` supports the Unicode character repertoire and encodes characters using between one and four bytes.

For example:

```text
A   -> 41
ã   -> C3 A3
€   -> E2 82 AC
😀  -> F0 9F 98 80
```

Oracle also has a legacy character set named:

```text
UTF8
```

Despite the name, Oracle `UTF8` is not the character set normally meant when modern applications refer to UTF-8.

For new Oracle databases and modern Unicode applications, `AL32UTF8` is the relevant character set.

### "ANSI"

"ANSI" is a historical and informal term frequently used by Windows applications to describe the system's legacy single-byte code page.

It does **not** identify one universal character encoding.

For Western European Windows systems, "ANSI" commonly refers to:

```text
Windows-1252
CP1252
```

The equivalent Oracle character set is:

```text
WE8MSWIN1252
```

Other Windows regions historically used other code pages.

For example:

```text
Windows-1250 -> Central European
Windows-1251 -> Cyrillic
Windows-1252 -> Western European
Windows-1253 -> Greek
```

Therefore:

```text
"ANSI" != one specific encoding
```

In Western European environments, however, the term very often means Windows-1252.

For technical documentation it is therefore preferable to say:

```text
Windows-1252 / CP1252
```

rather than simply:

```text
ANSI
```

## ISO-8859-1 is not Windows-1252

Another common source of confusion is ISO-8859-1.

The Oracle character sets are:

```text
WE8MSWIN1252   -> Windows-1252
WE8ISO8859P1   -> ISO-8859-1
```

They are closely related, but they are not the same encoding.

Oracle documents `WE8MSWIN1252` as a **single-byte binary superset** of `WE8ISO8859P1`.

Both encodings can represent common Western European text such as:

```text
João
José
coração
ação
avó
mañana
München
déjà
```

Characters such as:

```text
ã  é  ç  á  à  â  ó  ô  ú  ü  ñ
```

use the same byte values in both encodings.

This similarity is one of the reasons why distinguishing Windows-1252 from ISO-8859-1 can be difficult when only ordinary Western European text is available.

## Why were legacy encodings such as Windows-1252 used?

Older computers had far more restrictive memory, storage, and processing constraints than modern systems.

Single-byte encodings such as Windows-1252 were simple and efficient.

Each encoded character occupied one byte:

```text
A  -> 41
ã  -> E3
é  -> E9
```

That made assumptions such as:

```text
1 character ~= 1 byte
```

reasonable for many applications.

Applications could also use a character set specifically designed for the languages required in their region.

For Western Europe, Windows-1252 supported languages such as:

- Portuguese
- English
- Spanish
- French
- German
- Italian

very efficiently.

A Portuguese application therefore had little practical need to allocate representation space for thousands of Chinese, Japanese, Arabic, or other characters.

At the time, using a regional code page was often a sensible engineering choice.

## The limitation of regional character sets

The problem is that a single-byte character set has at most 256 byte values.

Its repertoire is therefore limited.

Windows-1252 can represent Portuguese very well:

```text
João
José
coração
ação
avó
amanhã
```

but it cannot represent many characters from other writing systems.

For example:

```text
Japanese:
こんにちは

Arabic:
مرحبا

Greek:
Καλημέρα

Chinese:
你好

Emoji:
😀
```

These characters simply do not have corresponding byte values in Windows-1252.

When software tries to convert such text into Windows-1252, several things may happen depending on the application and conversion API:

- an error may be raised;
- the character may be replaced;
- a fallback character such as `?` may be used;
- data may be silently lost.

This is one of the fundamental limitations of legacy regional encodings.

## Why UTF-8 became the preferred choice

UTF-8 solves this problem by providing an encoding for Unicode.

The same encoding can represent:

```text
Portuguese:
Olá João

Japanese:
こんにちは

Arabic:
مرحبا

Greek:
Καλημέρα

Chinese:
你好

Emoji:
😀
```

All of these can coexist in the same text:

```text
João said: Olá
Yuki said: こんにちは
Ahmed said: مرحبا
Nikos said: Καλημέρα
😀
```

There is no need to change the encoding depending on the language.

UTF-8 achieves this using a variable number of bytes per character.

For example:

```text
Character   Windows-1252   UTF-8
---------   ------------   --------
A           41             41
é           E9             C3 A9
ã           E3             C3 A3
€           80             E2 82 AC
```

ASCII characters still use one byte in UTF-8, while other characters use additional bytes.

This means that UTF-8 may require slightly more storage than Windows-1252 for some Western European text.

For example:

```text
João
```

Windows-1252:

```text
4A 6F E3 6F
```

UTF-8:

```text
4A 6F C3 A3 6F
```

However, modern systems generally prefer the flexibility and interoperability of UTF-8 over the small storage advantage of legacy single-byte encodings.

For new applications, APIs, databases, and integration platforms, UTF-8 is therefore normally the preferred choice.

Legacy encodings such as Windows-1252 remain important primarily because existing systems and external data sources still use them.

## Why encoding still matters in modern integrations

A modern application may use UTF-8 internally and still receive external data encoded differently.

A typical integration can receive data from:

- FTP or SFTP files
- file shares
- object storage
- REST APIs
- SOAP web services
- message queues
- legacy applications
- third-party systems
- exported CSV or text files
- browser-based applications

These sources are not necessarily homogeneous.

For example:

```text
System A -> UTF-8
System B -> Windows-1252
System C -> ISO-8859-1
System D -> unknown or incorrectly declared encoding
```

Even two files received by the same application may legitimately use different encodings.

This is why encoding detection and validation can still be relevant even when the destination database uses `AL32UTF8`.

## Browsers do not eliminate encoding problems

Web browsers are also part of the encoding story.

Modern web applications overwhelmingly use UTF-8, but text exchanged between browsers and servers is still ultimately transmitted as bytes.

HTML documents can declare their character encoding, for example:

```html
<meta charset="UTF-8">
```

HTTP responses can also identify an encoding through their content type.

Conceptually:

```text
Server bytes
     |
     | declared charset
     v
Browser decoding
     |
     v
Displayed characters
```

If the declared encoding does not match the actual bytes, the browser may decode the text incorrectly.

This can produce mojibake such as:

```text
João
```

being displayed as:

```text
JoÃ£o
```

Browsers can also receive byte sequences that are invalid for the declared encoding.

Similarly, text entered or submitted through a browser may contain Unicode characters that cannot later be represented by a legacy target character set.

For example, a user may enter:

```text
Meeting at 10€ 😀
```

The browser and web application may handle the text correctly as UTF-8.

But if a downstream integration attempts to store or export that text as Windows-1252:

```text
10€ -> representable
😀  -> not representable
```

the emoji cannot be converted to Windows-1252 without loss or an error.

Therefore, encoding problems are not limited to files or old applications.

They can appear anywhere bytes and text cross system boundaries.

## Invalid encoding vs unsupported character

These are related but different situations.

### Invalid byte sequence

The bytes do not form a valid sequence for the encoding being used.

For example, a sequence may be invalid UTF-8.

Conceptually:

```text
bytes
   |
   v
"These bytes are not valid UTF-8"
```

### Character not representable in the target character set

The source character is valid, but the destination encoding cannot represent it.

For example:

```text
😀
```

is a perfectly valid Unicode character.

It simply cannot be represented in Windows-1252.

Conceptually:

```text
valid Unicode character
        |
        v
convert to Windows-1252
        |
        v
no corresponding byte exists
```

This distinction becomes important when diagnosing integration failures.

## Why BLOB/BFILE inputs are useful for external data

`UTL_I18N.DETECT_CHARSET` can accept:

- `BFILE`
- `BLOB`
- `CLOB`
- `VARCHAR2`
- `NVARCHAR2`

For an external file or payload, `BLOB` or `BFILE` is particularly useful because the original byte stream can be analyzed before it has been interpreted as database character data.

A typical integration may receive data from:

- FTP/SFTP files
- file shares
- object storage
- REST or SOAP web services
- APIs
- message queues
- legacy applications
- third-party systems

These sources are not necessarily homogeneous. Two files received by the same application can legitimately use different encodings.

Once bytes have already been decoded incorrectly, some or all of the original encoding information may be lost.

## Detection is probabilistic

`UTL_I18N.DETECT_CHARSET` returns a result table containing:

```text
CHARSET
SCORE
```

The candidates are ordered by descending likelihood.

For example:

```text
WE8MSWIN1252  0.797947
EE8MSWIN1250  0.0718044
...
```

The first row is therefore the detector's most likely explanation of the byte sample.

In this lab, when a single detected character set is required, we select the first candidate: the one with the highest score.

This is a practical choice. It is not mathematical proof that the candidate was the source system's original encoding.

The bytes available to the detector, the similarity of candidate character sets, and the sample size all affect the result.

## WE8ISO8859P1 and WE8MSWIN1252

Oracle documents `WE8MSWIN1252` as a **single-byte binary superset** of `WE8ISO8859P1`.

This relationship explains an important result from this lab.

Characters that are common Western European characters, for example:

```text
ã  é  ç  á  à  â  ó  ô  ú  ü  ñ
```

are not useful discriminators between these two character sets because they are represented using the same byte values.

Therefore a byte stream that was actually generated as `WE8MSWIN1252` can contain no evidence that specifically requires Windows-1252.

### Ambiguous sample

The lab generated this text as Windows-1252:

```text
João and José visited Guimarães and stopped for café before returning to Lisbon.
```

The detector returned:

```text
WE8ISO8859P1  Score: 0.694688
```

For the bytes present in this particular sample, interpreting the data as ISO-8859-1 does not change the visible Portuguese characters.

That is why the subsequent conversion can still produce correct text even though the detector did not identify the exact character set used to generate the test BLOB.

## The practical difference: bytes 0x80-0x9F

The most useful byte range for distinguishing Windows-1252 from ISO-8859-1 is:

```text
0x80-0x9F
```

ISO-8859-1 uses this range for C1 control characters.

Windows-1252 instead assigns **27 graphic characters** to positions in this range and leaves five positions undefined.

The Windows-1252 graphic mappings are:

| Byte | Character | Unicode | Name |
|---|---:|---|---|
| `80` | `€` | U+20AC | EURO SIGN |
| `82` | `‚` | U+201A | SINGLE LOW-9 QUOTATION MARK |
| `83` | `ƒ` | U+0192 | LATIN SMALL LETTER F WITH HOOK |
| `84` | `„` | U+201E | DOUBLE LOW-9 QUOTATION MARK |
| `85` | `…` | U+2026 | HORIZONTAL ELLIPSIS |
| `86` | `†` | U+2020 | DAGGER |
| `87` | `‡` | U+2021 | DOUBLE DAGGER |
| `88` | `ˆ` | U+02C6 | MODIFIER LETTER CIRCUMFLEX ACCENT |
| `89` | `‰` | U+2030 | PER MILLE SIGN |
| `8A` | `Š` | U+0160 | LATIN CAPITAL LETTER S WITH CARON |
| `8B` | `‹` | U+2039 | SINGLE LEFT-POINTING ANGLE QUOTATION MARK |
| `8C` | `Œ` | U+0152 | LATIN CAPITAL LIGATURE OE |
| `8E` | `Ž` | U+017D | LATIN CAPITAL LETTER Z WITH CARON |
| `91` | `‘` | U+2018 | LEFT SINGLE QUOTATION MARK |
| `92` | `’` | U+2019 | RIGHT SINGLE QUOTATION MARK |
| `93` | `“` | U+201C | LEFT DOUBLE QUOTATION MARK |
| `94` | `”` | U+201D | RIGHT DOUBLE QUOTATION MARK |
| `95` | `•` | U+2022 | BULLET |
| `96` | `–` | U+2013 | EN DASH |
| `97` | `—` | U+2014 | EM DASH |
| `98` | `˜` | U+02DC | SMALL TILDE |
| `99` | `™` | U+2122 | TRADE MARK SIGN |
| `9A` | `š` | U+0161 | LATIN SMALL LETTER S WITH CARON |
| `9B` | `›` | U+203A | SINGLE RIGHT-POINTING ANGLE QUOTATION MARK |
| `9C` | `œ` | U+0153 | LATIN SMALL LIGATURE OE |
| `9E` | `ž` | U+017E | LATIN SMALL LETTER Z WITH CARON |
| `9F` | `Ÿ` | U+0178 | LATIN CAPITAL LETTER Y WITH DIAERESIS |

The following Windows-1252 positions are undefined:

```text
0x81
0x8D
0x8F
0x90
0x9D
```

This gives the compact set of Windows-1252 graphic characters that differ in this range:

```text
€  ‚  ƒ  „  …  †  ‡  ˆ  ‰  Š  ‹  Œ  Ž
‘  ’  “  ”  •  –  —  ˜  ™  š  ›  œ  ž  Ÿ
```

## Why the discriminating sample works

The lab then used:

```text
João paid €25 — “That’s expensive”, José said.
```

This introduces several characters from the Windows-1252-specific graphic range:

| Character | Windows-1252 byte |
|---|---:|
| `€` | `80` |
| `—` | `97` |
| `“` | `93` |
| `”` | `94` |
| `’` | `92` |

When this string is encoded as `WE8MSWIN1252`, these byte values give the detector much stronger evidence that the source is Windows-1252.

Observed result:

```text
WE8MSWIN1252  Score: 0.797947
```

By contrast, the first sample contained no comparable Windows-1252-specific evidence.

## The same characters are valid in Unicode

The fact that characters such as:

```text
€  —  “  ”  ’
```

are not graphic characters in ISO-8859-1 does not mean that they are Windows-1252-only characters in a general sense.

They are Unicode characters and are fully representable in `AL32UTF8`.

For example:

```text
Character    WE8MSWIN1252    AL32UTF8
---------    ------------    ---------
€            80              E2 82 AC
—            97              E2 80 94
“            93              E2 80 9C
”            94              E2 80 9D
’            92              E2 80 99
```

The same visible text can therefore be correctly represented by both Windows-1252 and UTF-8, but with different underlying bytes.

This is exactly what `DETECT_CHARSET` analyzes.

## Lossy conversion can destroy discriminating evidence

The lab also intentionally attempted to generate `WE8ISO8859P1` bytes from a string containing:

```text
€  —  “  ”  ’
```

Because those graphic characters are not representable in `WE8ISO8859P1`, the conversion replaced them.

The round trip showed replacement characters rather than the originals.

Conceptually:

```text
Original:
João paid €25 — “That’s expensive”, José said.

        |
        | conversion to WE8ISO8859P1
        v

Lossy result:
João paid ?25 ? ?That?s expensive?, José said.

In this lab, the unrepresentable character is replaced with a question mark (?).
```

Once this has happened, the original Windows-1252/Unicode-specific information is gone.

A later call to `DETECT_CHARSET` sees only the bytes that survived the lossy conversion. It cannot infer which characters were present before the replacement occurred.

## Mojibake vs lossy conversion

These are related but different failure modes.

### Mojibake

The original bytes still exist, but are interpreted using the wrong encoding.

Example:

```text
João -> JoÃ£o
```

The information may sometimes be recoverable because the original byte pattern is still represented indirectly.

### Lossy conversion

A character cannot be represented in the target character set and is replaced.

For example:

```text
€ -> ?

In this lab, the unrepresentable character is replaced with a question mark (?).
```

After replacement, the original character is no longer encoded in the resulting data.

This is why preserving original source bytes can be important in integration pipelines.

## Detection vs conversion vs validation

These operations answer different questions.

### `DETECT_CHARSET`

```text
What character set most likely explains these bytes?
```

The answer is probabilistic.

### `DBMS_LOB.CONVERTTOCLOB`

```text
Assuming these bytes use this source character set,
convert them into database character data.
```

The procedure trusts the supplied `blob_csid`.

### `VALIDATE_CHARACTER_ENCODING`

```text
Is this resulting character data structurally valid
for its Oracle character set?
```

A result of `0` means valid encoding.

It does **not** mean:

```text
The original text was preserved correctly.
```

For example, this result can be valid `AL32UTF8`:

```text
?25 ? ?That?s expensive?
```

even though the intended source was:

```text
€25 — “That’s expensive”
```

Every `?` is a valid Unicode character. Encoding validation has no knowledge that a different character was originally intended.

## Sample size and information content

The lab deliberately placed the Windows-1252 discriminators later in a longer source string.

With:

```text
sample_size = 60
```

the detector did not inspect the later bytes and returned:

```text
WE8ISO8859P1
```

Using the complete input returned:

```text
WE8MSWIN1252
```

This demonstrates an important principle:

> Detection quality depends not only on the number of bytes analyzed, but on whether those bytes contain information that distinguishes the candidate encodings.

A large sample containing only ASCII or characters shared by multiple candidate encodings can still be ambiguous.

A smaller sample containing discriminating characters may provide stronger evidence.

## Practical interpretation of detection results

A useful mental model is:

```text
Input bytes
     |
     v
UTL_I18N.DETECT_CHARSET
     |
     v
Ranked candidates
     |
     +-- WE8MSWIN1252   0.797947
     +-- EE8MSWIN1250   0.0718044
     +-- ...
     |
     v
Select first row
     |
     v
Best available hypothesis
```

The first row is not absolute truth. It is the detector's strongest hypothesis for the bytes available.

A production integration may combine detection with other information such as:

- documented partner specifications;
- HTTP `Content-Type`;
- file metadata;
- known source-system configuration;
- expected language;
- presence of a BOM;
- application-specific validation rules.

Character-set detection is most useful when the source encoding is unknown, unreliable, inconsistent, or incorrectly declared.

## The other new 26ai procedures

Oracle AI Database 26ai also introduces:

- `UTL_I18N.DETECT_LANGUAGE`
- `UTL_I18N.DETECT_LANGUAGE_CHARSET`

They use the same family of detection functionality and also return ranked results.

They are mentioned for completeness, while this lab deliberately stays focused on character-set detection, conversion, and validation.

## Key takeaways

1. Text characters and encoded bytes are different concepts.
2. A character set defines which characters can be represented, while an encoding defines how those characters are represented as bytes.
3. Oracle commonly uses the term *character set* for definitions that effectively include both repertoire and byte encoding.
4. `AL32UTF8` is Oracle's modern UTF-8 character set.
5. Windows-1252, represented in Oracle as `WE8MSWIN1252`, is one of the encodings historically referred to as "ANSI" in Western Windows environments.
6. "ANSI" is not a precise encoding name and should generally be avoided in technical specifications.
7. Windows-1252 represents Portuguese and other Western European languages well, but cannot represent many characters from Japanese, Arabic, Chinese, Greek, emoji, and other Unicode ranges.
8. UTF-8 can represent all of these characters within the same encoding, which is a major reason it is preferred in modern systems.
9. Encoding problems can occur in browser traffic, files, APIs, queues, databases, and any other integration boundary.
10. Invalid byte sequences and valid characters that are unsupported by a target encoding are different problems.
11. `UTL_I18N.DETECT_CHARSET` returns a ranked list of candidate character sets and scores.
12. This lab selects the first candidate when one result is required, because it is the detector's highest-ranked hypothesis.
13. The highest-ranked candidate is not mathematical proof of the source encoding.
14. Similar encodings such as Windows-1252 and ISO-8859-1 may be impossible to distinguish when the sample contains no discriminating bytes.
15. Preserving the original bytes is important because incorrect or lossy conversions can destroy the information required for later detection.
16. Detection, conversion, and encoding validation answer different questions and should not be treated as equivalent operations.

## References

- Oracle AI Database 26ai — `UTL_I18N`  
  https://docs.oracle.com/en/database/oracle/oracle-database/26/arpls/UTL_I18N.html
- Oracle AI Database 26ai — Changes in This Release  
  https://docs.oracle.com/en/database/oracle/oracle-database/26/arpls/release-changes.html
- Oracle Database Migration Assistant for Unicode Guide — `WE8MSWIN1252` is documented as a single-byte binary superset of `WE8ISO8859P1`  
  https://docs.oracle.com/pls/topic/lookup?ctx=en/database/oracle/oracle-database/18/nlspg&id=DUMAG-GUID-3CA04A80-4870-469F-9FBB-0578779E7622
- Unicode Consortium — Windows CP1252 mapping table  
  https://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1252.TXT

# Sample Size and Detection Confidence

This document contains the lab experiment that tests the `sample_size` parameter. The general encoding concepts and conversion API are documented separately.

## Why sample only part of the input?

`UTL_I18N.DETECT_CHARSET` can analyze only a specified number of bytes through `sample_size`.

For very large LOBs or files, limiting the sample can reduce how much data the detector must inspect. The trade-off is that the selected portion may not contain the bytes needed to distinguish similar encodings.

When `sample_size` is `NULL`, the detector uses the full input length.

## Test design

The source is encoded as `WE8MSWIN1252`:

```text
João and José visited Guimarães and stopped for café before returning to Lisbon.
After dinner João paid €25 — “That’s expensive”, José said.
```

The first part contains characters that are common to both Windows-1252 and ISO-8859-1.

The stronger Windows-1252 discriminators — `€`, `—`, `“`, `”`, and `’` — appear later.

## Full sample

Observed result:

```text
Detected charset   : WE8MSWIN1252
Detection score    : 0.721792
Converted text     : João and José visited Guimarães and stopped for café before returning to Lisbon. After dinner João paid €25 — “That’s expensive”, José said.
Conversion warning : 0
Validation result  : 0
```

The detector sees the later Windows-1252-specific bytes and selects the expected source encoding.

## `sample_size = 60`

Observed result:

```text
Detected charset   : WE8ISO8859P1
Detection score    : 0.704489
Converted text     : João and José visited Guimarães and stopped for café before returning to Lisbon. After dinner João paid ?25 ? ?That?s expensive?, José said.
Conversion warning : 0
Validation result  : 0
```

The first 60 bytes do not contain the distinguishing Windows-1252 punctuation. The detector therefore selects the closely related `WE8ISO8859P1` profile.

## What this experiment proves

### 1. Sampling can change the detected character set

The underlying source bytes did not change. Only the number of bytes analyzed changed.

### 2. A score should not be treated as a universal correctness threshold

The incorrect result still received a score of approximately `0.70`.

This lab therefore does not recommend rules such as:

```text
score > 0.70 -> always safe to convert automatically
```

Any production threshold should be tested against representative data and combined with source context.

### 3. `warning = 0` does not validate the source assumption

`DBMS_LOB.CONVERTTOCLOB` successfully performed the conversion according to the character set it was given. It had no way to know that the source assumption was wrong.

### 4. `VALIDATE_CHARACTER_ENCODING = 0` does not mean the original text was preserved

The resulting question marks are valid characters in `AL32UTF8`, so the CLOB is structurally valid even though the intended Windows-1252 punctuation was lost.

## Practical guidance

For the lab, full-input detection is the default because it gives the detector the most available evidence.

For large production inputs, sampling can be a legitimate performance optimization, but it should be treated as an **accuracy/performance trade-off**. Representative testing is important, especially when the characters that distinguish likely encodings may appear only occasionally or later in the data.

## Reference

- Oracle AI Database 26ai — `UTL_I18N.DETECT_CHARSET`  
  https://docs.oracle.com/en/database/oracle/oracle-database/26/arpls/UTL_I18N.html

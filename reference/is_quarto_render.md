# Detect Quarto Rendering Context

Determines whether code is executing as part of a Quarto render. Quarto
exposes the source document name through `QUARTO_DOCUMENT_FILE` for
every execution engine.

## Usage

``` r
is_quarto_render()
```

## Value

Logical indicating whether a Quarto document is being rendered.

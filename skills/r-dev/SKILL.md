---
name: r-dev
description: R development conventions using renv for isolation, styler/lintr for code quality, tidyverse for data manipulation, and testthat for testing. Use when writing R code in any project.
---

# R Development Conventions

## Environment and Package Management (`renv`)
- You must use `renv` to maintain project dependency isolation. Do not install packages globally using baseline `install.packages()`.
- When a new package is required, use `renv::install("package_name")` followed immediately by `renv::snapshot()` to update the `renv.lock` file.
- Never commit code that relies on local paths outside the project directory. Always use relative paths initialized via the `here` package (e.g., `here::here("data", "raw_file.csv")`).

## Style and Code Quality (`styler`, `lintr`)
- You must format and lint all R scripts before presenting code or generating a commit.
- Follow the tidyverse style guide.
  - Automatically format code using: `styler::style_file("path/to/file.R")` or `styler::style_dir()`
- Use `lintr` to enforce code quality.
  - Run lint checks via: `lintr::lint("path/to/file.R")`
  - **Rule:** Eliminate all warnings and errors. Pay specific attention to avoiding absolute paths, trailing whitespace, and lines exceeding 80 characters.

## Programming Paradigm and Syntax
- Prefer Tidyverse packages (`dplyr`, `tidyr`, `ggplot2`, `purrr`) for data manipulation and visualization over base R equivalents, unless performance constraints dictate otherwise.
- Use the native R pipe operator `|>` (introduced in R 4.1) for chaining operations. Do not use the older `magrittr` pipe `%>%` unless working in a legacy script that explicitly requires it.
- To prevent namespace conflicts, explicitly scope functions from external packages using the `::` operator (e.g., `dplyr::filter()` instead of just `filter()`), especially within functions or background scripts.
- Avoid explicit `for` or `while` loops for data transformations. Use vectorized base R operations or the `purrr::map()` family of functions to manipulate elements.

## Testing (`testthat`)
- All unit and integration tests must be written using the `testthat` framework.
- Place all test scripts inside the `tests/testthat/` directory. Test filenames must match the pattern `test-*.R` (e.g., `test-data_processing.R`).
- Run the entire test suite using `devtools::test()` or `testthat::test_dir("tests/testthat")`.
- If a test creates a temporary file or alters options, it must clean up after itself using `on.exit()` or `withr::defer()`.

## Documentation and Robustness
- Every user-defined function must be documented using `roxygen2` comments directly preceding the function definition. You must specify `@param`, `@return`, and `@examples` where applicable.
- Always validate function inputs at the top of the execution block using `stopifnot()`, `cli::cli_abort()`, or the `checkmate` package to ensure types and dimensions match expectations.
- R keeps objects in RAM. If processing large datasets, proactively call `rm()` on heavy intermediate objects and force garbage collection with `gc()` to keep the footprint minimal.
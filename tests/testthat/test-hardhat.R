test_that("Training regression", {

  data("ames", package = "modeldata")

  x <- ames[-which(names(ames) == "Sale_Price")]
  y <- ames$Sale_Price

  expect_error(
    fit <- tabnet_fit(x, y, epochs = 1),
    regexp = NA
  )

  expect_error(
    fit <- tabnet_fit(Sale_Price ~ ., data = ames, epochs = 1),
    regexp = NA
  )

  expect_error(
    predict(fit, x),
    regexp = NA
  )

  expect_error(
    fit <- tabnet_fit(x, y, epochs = 2, verbose = TRUE),
    regexp = NA
  )
})

test_that("Training classification", {

  data("attrition", package = "modeldata")

  x <- attrition[-which(names(attrition) == "Attrition")]
  y <- attrition$Attrition

  expect_error(
    fit <- tabnet_fit(x, y, epochs = 1),
    regexp = NA
  )

  expect_error(
    predict(fit, x, type = "prob"),
    regexp = NA
  )

  expect_error(
    predict(fit, x),
    regexp = NA
  )

})

test_that("errors when using an argument that do not exist", {

  data("ames", package = "modeldata")

  x <- ames[-which(names(ames) == "Sale_Price")]
  y <- ames$Sale_Price

  expect_error(
    fit <- tabnet_fit(x, y, epochsas = 1),
    "unused argument"
  )

})

test_that("works with validation split", {

  data("attrition", package = "modeldata")

  x <- attrition[-which(names(attrition) == "Attrition")]
  y <- attrition$Attrition

  expect_error(
    fit <- tabnet_fit(x, y, epochs = 1, valid_split = 0.2),
    regexp = NA
  )

  expect_error(
    fit <- tabnet_fit(x, y, epochs = 1, valid_split = 0.2, verbose = TRUE),
    regexp = NA
  )

})

test_that("can train from a recipe", {

  library(recipes)
  data("attrition", package = "modeldata")

  rec <- recipe(Attrition ~ ., data = attrition) %>%
    step_normalize(all_numeric(), -all_outcomes())

  expect_error(
    fit <- tabnet_fit(rec, attrition, epochs = 1, valid_split = 0.25,
                    verbose = TRUE),
    regexp = NA
  )

  expect_error(
    predict(fit, attrition),
    regexp = NA
  )

})

test_that("data-frame with missing value makes training fails with explicit message", {

  data("attrition", package = "modeldata")

  x <- attrition[-which(names(attrition) == "Attrition")]
  y <- attrition$Attrition
  y_missing <- y
  y_missing[1] <- NA

  # numerical missing
  x_missing <- x
  x_missing[1,"Age"] <- NA

  expect_error(
    miss_fit <- tabnet_fit(x_missing, y, epochs = 1),
    regexp = "missing"
  )

  # categorical missing
  x_missing <- x
  x_missing[1,"BusinessTravel"] <- NA

  expect_error(
    miss_fit <- tabnet_fit(x_missing, y, epochs = 1),
    regexp = "missing"
  )

  # missing in outcome
  expect_error(
    miss_fit <- tabnet_fit(x, y_missing, epochs = 1),
    regexp = "missing"
  )

})

test_that("data-frame with missing value makes inference fails with explicit message", {

  data("attrition", package = "modeldata")

  x <- attrition[-which(names(attrition) == "Attrition")]
  y <- attrition$Attrition
  #
  fit <- tabnet_fit(x, y, epochs = 1)

  # numerical missing
  x_missing <- x
  x_missing[1,"Age"] <- NA

  # predict with numerical missing
  expect_error(
    predict(fit, x_missing),
    regexp = "missing"
  )
  # categorical missing
  x_missing <- x
  x_missing[1,"BusinessTravel"] <- NA

  # predict
  expect_error(
    predict(fit, x_missing),
    regexp = "missing"
  )

})
test_that("inference works with missings in the response vector", {

  library(recipes)
  data("attrition", package = "modeldata")
  rec <- recipe(EnvironmentSatisfaction ~ ., data = attrition) %>%
    step_normalize(all_numeric(), -all_outcomes())
  fit <- tabnet_fit(rec, attrition, epochs = 1, valid_split = 0.25,
                    verbose = TRUE)
  # predict with empty vector
  attrition[["EnvironmentSatisfaction"]] <-NA
  expect_error(
    predict(fit, attrition),
    regexp = NA
  )

  # predict with wrong class
  attrition[["EnvironmentSatisfaction"]] <-NA_character_
  expect_error(
    predict(fit, attrition),
    regexp = NA
  )

  # predict with list column
  attrition[["EnvironmentSatisfaction"]] <- list(NA)
  expect_error(
    predict(fit, attrition),
    regexp = NA
  )

})


test_that("serialization with saveRDS just works", {

  data("ames", package = "modeldata")

  x <- ames[-which(names(ames) == "Sale_Price")]
  y <- ames$Sale_Price

  fit <- tabnet_fit(x, y, epochs = 1)

  tmp <- tempfile("model", fileext = "rds")
  saveRDS(fit, tmp)

  fit2 <- readRDS(tmp)

  expect_equal(
    predict(fit, ames),
    predict(fit2, ames)
  )

  expect_equal(as.numeric(fit2$fit$network$.check), 1)

})

test_that("scheduler works", {

  data("ames", package = "modeldata")

  x <- ames[-which(names(ames) == "Sale_Price")]
  y <- ames$Sale_Price

  expect_error(
    fit <- tabnet_fit(x, y, epochs = 3, lr_scheduler = "step",
                      lr_decay = 0.1, step_size = 1),
    regexp = NA
  )

  sc_fn <- function(optimizer) {
    torch::lr_step(optimizer, step_size = 1, gamma = 0.1)
  }

  expect_error(
    fit <- tabnet_fit(x, y, epochs = 3, lr_scheduler = sc_fn,
                      lr_decay = 0.1, step_size = 1),
    regexp = NA
  )

})

test_that("checkpoints works", {

  data("ames", package = "modeldata")

  x <- ames[-which(names(ames) == "Sale_Price")]
  y <- ames$Sale_Price

  expect_error(
    fit <- tabnet_fit(x, y, epochs = 3, checkpoint_epochs = 1),
    regexp = NA
  )

  expect_error(
    p1 <- predict(fit, x, epoch = 1),
    regexp = NA
  )

  expect_error(
    p2 <- predict(fit, x, epoch = 2),
    regexp = NA
  )

  expect_error(
    p3 <- predict(fit, x, epoch = 3),
    regexp = NA
  )

  expect_equal(p3, predict(fit, x))

})

test_that("print module works", {

  testthat::local_edition(3)
  testthat::skip_on_os("linux")
  testthat::skip_on_os("windows")

  data("ames", package = "modeldata")

  x <- ames[-which(names(ames) == "Sale_Price")]
  y <- ames$Sale_Price

  expect_error(
    fit <- tabnet_fit(x, y, epochs = 1),
    regexp = NA
  )

  withr::with_options(new = c(cli.width = 50),
                      expect_snapshot_output(fit))

})


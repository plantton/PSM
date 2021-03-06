##' A function to convert the identification data contained in an
##' `mzRident` object (as defined in the `mzR` package) to a
##' `data.frame`. Each row represents a scan, which can however be
##' repeated several times if the PSM matches multiple proteins and/or
##' contains two or more modifications.
##'
##' @title Coerce PSM data to a `data.frame`
##' 
##' @param from An object of class `mzRident` defined in the `mzR`
##'     package.
##' 
##' @return A `data.frame`
##' 
##' @author Laurent Gatto
##' 
##' @name as
##' 
##' @rdname mzRident2dfr
##' 
##' @aliases as.data.frame.mzRident
##'
##' @export
##'
##' @importFrom BiocGenerics fileName
##' 
##' @examples
##' ## find path to an mzIdentML file
##' f <- msdata::ident(full.names = TRUE, pattern = "TMT")
##' basename(f)
##' 
##' library("mzR")
##' x <- openIDfile(f)
##' x
##' as(x, "data.frame")
setAs("mzRident", "data.frame",
      function(from) {
          stopifnot(requireNamespace("mzR"))
          ## peptide spectrum matching
          iddf <- factorsAsStrings(mzR::psms(from))
          ## add file raw and mzid provenances
          src <- basename(mzR::sourceInfo(from))
          if (length(src) > 1) ## see issue #261
              src <- paste(src, collapse = ";")
          iddf$spectrumFile <- src
          iddf$idFile <- basename(fileName(from))
          ## add scores
          scores <- factorsAsStrings(mzR::score(from))
          if (nrow(scores)) { ## see issue #261
              stopifnot(identical(iddf[, 1], scores[, 1]))
              iddf <- cbind(iddf, scores[, -1])
          }
          ## add modification
          mods <- factorsAsStrings(mzR::modifications(from))
          names(mods)[-1] <- makeCamelCase(names(mods), prefix = "mod")[-1]
          iddf <- merge(iddf, mods,
                        by.x = c("spectrumID", "sequence"),
                        by.y = c("spectrumID",  "modSequence"),
                        suffixes = c("", ".y"),
                        all = TRUE, sort = FALSE)
          iddf[, "spectrumID.y"] <- NULL
          ## add substitutions
          subs <- factorsAsStrings(mzR::substitutions(from))
          names(subs)[-1] <- makeCamelCase(names(subs), prefix = "sub")[-1]
          iddf <- merge(iddf, subs,
                        by.x = c("spectrumID" = "sequence"),
                        by.y = c("spectrumID" = "subSequence"),
                        suffixes = c("", ".y"),
                        all = TRUE, sort = FALSE)
          iddf[, "spectrumID.y"] <- NULL
          iddf
      })

as.data.frame.mzRident <-
    function(x, row.names = NULL, optional = FALSE, ...) as(x, "data.frame")

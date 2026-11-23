# João Gabriel Fanti
# João Victor Leal Gonçalves
# João Pedro Nossol
# Lucas Santana
# DS803 - Inteligência Computacional Aplicada I (UFPR)
# Trabalho: Reconhecimento de Padrões - É morcego?
# Módulo 00: Carregamento de pacotes, utilitários e sementes iniciais

set.seed(2026)

#-------------------------------------------------------------------------------
### Pacotes necessários

library(RSNNS)
library(caret)
library(ggplot2)
library(pROC)
library(e1071)
library(smotefamily)
library(MLmetrics)

#-------------------------------------------------------------------------------
### Diretórios do projeto

pasta_estado <- file.path(getwd(), "estado")
pasta_saida <- file.path(getwd(), "resultados")
pasta_figuras <- file.path(pasta_saida, "figuras")

dir.create(pasta_estado, showWarnings = FALSE, recursive = TRUE)
dir.create(pasta_saida, showWarnings = FALSE, recursive = TRUE)
dir.create(pasta_figuras, showWarnings = FALSE, recursive = TRUE)

salvar_csv <- function(dados, caminho) {
  dir.create(dirname(caminho), showWarnings = FALSE, recursive = TRUE)
  write.csv(dados, caminho, row.names = FALSE, fileEncoding = "UTF-8")
}

#-------------------------------------------------------------------------------
### Leitura e pré-processamento dos dados (wpc50.dat + Names.txt)

carregar_dados <- function(
  arquivo_wpc = "wpc50.dat",
  arquivo_nomes = "Names.txt"
) {
  if (!file.exists(arquivo_wpc)) stop("Arquivo não encontrado: ", arquivo_wpc)
  if (!file.exists(arquivo_nomes)) stop("Arquivo não encontrado: ", arquivo_nomes)

  X <- as.matrix(read.table(arquivo_wpc, header = FALSE))
  storage.mode(X) <- "double"
  colnames(X) <- sprintf("PC%02d", seq_len(ncol(X)))

  nomes <- trimws(readLines(arquivo_nomes, warn = FALSE, encoding = "UTF-8"))
  nomes <- nomes[nzchar(nomes)]

  if (nrow(X) != length(nomes)) {
    stop("Inconsistência de linhas: wpc50.dat=", nrow(X), ", Names.txt=", length(nomes))
  }
  if (any(!is.finite(X))) {
    stop("Valores não finitos encontrados em wpc50.dat.")
  }

  list(
    X = X,
    X_l2 = normalizar_l2(X),
    nomes = nomes,
    indices = seq_along(nomes)
  )
}

normalizar_l2 <- function(X) {
  normas <- sqrt(rowSums(X^2))
  normas[normas == 0] <- 1
  X / normas
}

# Distância cosseno mínima de cada organismo até um conjunto de índices de referência
distancia_cosseno_minima <- function(X_l2, indices_ref) {
  sims <- X_l2 %*% t(X_l2[indices_ref, , drop = FALSE])
  sims <- pmin(pmax(sims, -1), 1)
  dists <- 1 - sims
  pos_min <- max.col(-dists, ties.method = "first")
  list(
    dist_min = dists[cbind(seq_len(nrow(X_l2)), pos_min)],
    ref_mais_proximo = indices_ref[pos_min]
  )
}

#-------------------------------------------------------------------------------
### Sementes iniciais (Rodada 0) — pesquisa preliminar na literatura
# 10 morcegos (cobrindo as duas subordens: Yinpterochiroptera e Yangochiroptera)
# e 39 não-morcegos estratificados (incluindo mamíferos próximos / hard negatives)

obter_sementes_iniciais <- function(nomes) {
  sementes_pos <- data.frame(
    nome = c(
      # Yinpterochiroptera
      "Pteropus_alecto",
      "Cynopterus_brachyotis",
      "Rousettus_aegyptiacus",
      "Rhinolophus_formosae",
      "Hipposideros_armiger",
      # Yangochiroptera
      "Myotis_bechsteinii",
      "Artibeus_jamaicensis",
      "Desmodus_rotundus",
      "Pipistrellus_abramus",
      "Tadarida_teniotis"
    ),
    grupo = c(
      "Yinpterochiroptera / Pteropodidae",
      "Yinpterochiroptera / Pteropodidae",
      "Yinpterochiroptera / Pteropodidae",
      "Yinpterochiroptera / Rhinolophidae",
      "Yinpterochiroptera / Hipposideridae",
      "Yangochiroptera / Vespertilionidae",
      "Yangochiroptera / Phyllostomidae",
      "Yangochiroptera / Phyllostomidae",
      "Yangochiroptera / Vespertilionidae",
      "Yangochiroptera / Molossidae"
    ),
    classe = 1L,
    stringsAsFactors = FALSE
  )

  sementes_neg <- data.frame(
    nome = c(
      # Fungos e plantas
      "Candida_bracarensis", "Saccharomyces_cerevisiae", "Arabidopsis_thaliana",
      # Invertebrados
      "Drosophila_melanogaster", "Octopus_vulgaris",
      # Peixes, anfíbios, répteis e aves
      "Danio_rerio", "Cyprinus_carpio", "Salmo_salar",
      "Xenopus_laevis", "Alligator_mississippiensis",
      "Gallus_gallus", "Falco_peregrinus", "Struthio_camelus",
      # Mamíferos não-placentários e basais
      "Ornithorhynchus_anatinus", "Macropus_robustus", "Didelphis_virginiana",
      "Loxodonta_africana", "Dasypus_novemcinctus",
      # Primatas, roedores e lagomorfos
      "Homo_sapiens", "Pan_troglodytes", "Macaca_mulatta",
      "Mus_musculus", "Rattus_norvegicus", "Oryctolagus_cuniculus",
      # Laurasiatheria (mamíferos evolutivamente mais próximos aos morcegos)
      "Canis_lupus", "Felis_catus", "Acinonyx_jubatus", "Ursus_arctos", "Phoca_vitulina",
      "Bos_taurus", "Sus_scrofa", "Camelus_dromedarius", "Equus_caballus",
      "Balaenoptera_musculus", "Tursiops_truncatus",
      "Erinaceus_europaeus", "Sorex_araneus", "Talpa_europaea", "Manis_pentadactyla"
    ),
    grupo = c(
      rep("Fungi", 2), "Plantae",
      "Arthropoda", "Mollusca",
      rep("Actinopterygii", 3), "Amphibia", "Reptilia", rep("Aves", 3),
      rep("Mammalia (basal)", 5),
      rep("Mammalia (Euarchontoglires)", 6),
      rep("Mammalia (Laurasiatheria)", 15)
    ),
    classe = 0L,
    stringsAsFactors = FALSE
  )

  sementes <- rbind(sementes_pos, sementes_neg)
  sementes$indice <- match(sementes$nome, nomes)
  if (anyNA(sementes$indice)) {
    faltando <- sementes$nome[is.na(sementes$indice)]
    stop("Sementes não encontradas em Names.txt: ", paste(faltando, collapse = ", "))
  }
  sementes[, c("indice", "nome", "classe", "grupo")]
}

#-------------------------------------------------------------------------------
### SMOTE customizado compatível com caret::trainControl(sampling = ...)
# Usa smotefamily::SMOTE dentro de cada dobra de validação cruzada (sem vazamento)

criar_smote_caret <- function(K = 5, dup_size = 6) {
  list(
    name = "SMOTE_custom",
    func = function(x, y) {
      y_num <- ifelse(as.character(y) == "Morcego", 1L, 0L)
      n_pos <- sum(y_num == 1L)
      if (n_pos < 2) {
        return(list(x = x, y = y))
      }
      k_eff <- min(K, n_pos - 1L)
      res <- smotefamily::SMOTE(
        X = as.data.frame(x),
        target = y_num,
        K = k_eff,
        dup_size = dup_size
      )
      df_out <- res$data
      y_novo <- factor(
        ifelse(as.character(df_out$class) == "1", "Morcego", "Outro"),
        levels = levels(y)
      )
      x_novo <- df_out[, setdiff(names(df_out), "class"), drop = FALSE]
      colnames(x_novo) <- colnames(x)
      list(x = x_novo, y = y_novo)
    },
    first = TRUE
  )
}

#-------------------------------------------------------------------------------
### Métricas completas (Acurácia, Sensibilidade, Especificidade, Precisão, F1, AUC)

calcular_metricas_binarias <- function(y_real, y_pred, prob_morcego = NULL) {
  cm <- caret::confusionMatrix(
    data = factor(y_pred, levels = c("Morcego", "Outro")),
    reference = factor(y_real, levels = c("Morcego", "Outro")),
    positive = "Morcego",
    mode = "everything"
  )
  tab <- cm$table
  vp <- as.numeric(tab["Morcego", "Morcego"])
  fn <- as.numeric(tab["Outro", "Morcego"])
  fp <- as.numeric(tab["Morcego", "Outro"])
  vn <- as.numeric(tab["Outro", "Outro"])

  roc_auc <- NA_real_
  if (!is.null(prob_morcego) && length(unique(y_real)) == 2) {
    roc_obj <- pROC::roc(
      response = factor(y_real, levels = c("Outro", "Morcego")),
      predictor = prob_morcego,
      quiet = TRUE
    )
    roc_auc <- as.numeric(pROC::auc(roc_obj))
  }

  data.frame(
    VP = vp,
    VN = vn,
    FP = fp,
    FN = fn,
    Acuracia = as.numeric(cm$overall["Accuracy"]),
    Sensibilidade = as.numeric(cm$byClass["Sensitivity"]),
    Especificidade = as.numeric(cm$byClass["Specificity"]),
    Precisao = as.numeric(cm$byClass["Pos Pred Value"]),
    F1_score = as.numeric(cm$byClass["F1"]),
    ROC_AUC = roc_auc,
    stringsAsFactors = FALSE
  )
}

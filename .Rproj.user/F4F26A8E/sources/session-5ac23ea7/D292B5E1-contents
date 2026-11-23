# João Gabriel Fanti
# João Victor Leal Gonçalves
# João Pedro Nossol
# Lucas Santana
# DS803 - Inteligência Computacional Aplicada I (UFPR)
# Etapa 3: Enriquecimento da base, ajuste fino e benchmark do MLP (caret + mlpWeightDecay)

source(file.path("R", "00_setup.R"))

################################################################################
### ETAPA 3 - BENCHMARK DO MLP (caret + mlpWeightDecay)
################################################################################

arq_base_final <- file.path(pasta_estado, "base_supervisionada.csv")
if (!file.exists(arq_base_final)) {
  stop("Base supervisionada não encontrada em ", arq_base_final,
       "\nExecute primeiro R/02_prospeccao_mlp.R e finalize a prospecção (--finalizar).")
}

dados <- carregar_dados()
base_sup <- read.csv(arq_base_final, stringsAsFactors = FALSE)
base_sup <- base_sup[order(base_sup$indice), ]

y_fator <- factor(
  ifelse(base_sup$classe == 1L, "Morcego", "Outro"),
  levels = c("Morcego", "Outro")
)

n_morcegos <- sum(base_sup$classe == 1L)
cat("========================================================================\n")
cat(sprintf("  ETAPA 3 — Benchmark MLP (caret + mlpWeightDecay) | %d morcegos / %d total\n",
            n_morcegos, nrow(base_sup)))
cat("========================================================================\n")

# Divisão estratificada 80% treino / 20% teste (holdout nunca visto no treino)
set.seed(2026)
idx_treino <- createDataPartition(y_fator, p = 0.80, list = FALSE)[, 1]
idx_teste <- setdiff(seq_len(nrow(base_sup)), idx_treino)

cat(sprintf("Treino (80%%): %d organismos (%d morcegos)\n",
            length(idx_treino), sum(base_sup$classe[idx_treino] == 1L)))
cat(sprintf("Teste  (20%%): %d organismos (%d morcegos)\n",
            length(idx_teste), sum(base_sup$classe[idx_teste] == 1L)))

# Função auxiliar para montar data.frame conforme pré-processamento escolhido
montar_df <- function(tipo_prep) {
  mat <- if (tipo_prep == "L2") dados$X_l2 else dados$X
  df <- as.data.frame(mat)
  df$Classe <- y_fator
  df
}

#-------------------------------------------------------------------------------
### 3A — Comparação de pré-processamento e estratégias de enriquecimento (CV 5x5)
# Estratégias testadas estritamente dentro das dobras de CV (zero vazamento):
#   1) Sem balanceamento (raw)
#   2) Upsampling (sampling = "up", nativo do caret)
#   3) SMOTE (smotefamily integrado ao caret::trainControl)

cat("\n[1/3] Comparando pré-processamento (Z-score vs L2) e enriquecimento (Raw vs Up vs SMOTE)...\n")

combinacoes <- expand.grid(
  Preprocessamento = c("Z-score", "L2"),
  Enriquecimento = c("Sem_balanceamento", "Upsampling", "SMOTE"),
  stringsAsFactors = FALSE
)

smote_hook <- criar_smote_caret(K = 5, dup_size = 6)
# Em RSNNS::mlpWeightDecay, decay eficaz fica na faixa 1e-5 .. 1e-3
grade_ablacao <- expand.grid(size = c(10, 20), decay = c(1e-5, 1e-4, 1e-3))

res_ablacao_lista <- list()

for (i in seq_len(nrow(combinacoes))) {
  prep_nome <- combinacoes$Preprocessamento[i]
  enr_nome <- combinacoes$Enriquecimento[i]

  df_all <- montar_df(prep_nome)
  df_tr <- df_all[idx_treino, , drop = FALSE]

  sampling_arg <- if (enr_nome == "Sem_balanceamento") {
    NULL
  } else if (enr_nome == "Upsampling") {
    "up"
  } else {
    smote_hook
  }

  preproc_arg <- c("center", "scale")

  set.seed(2026)
  ctrl <- caret::trainControl(
    method = "repeatedcv",
    number = 5,
    repeats = 3,
    classProbs = TRUE,
    summaryFunction = prSummary,
    sampling = sampling_arg,
    savePredictions = "final"
  )

  mod <- suppressWarnings(caret::train(
    Classe ~ .,
    data = df_tr,
    method = "mlpWeightDecay",
    metric = "F",
    preProcess = preproc_arg,
    trControl = ctrl,
    tuneGrid = grade_ablacao,
    maxit = 250
  ))

  preds_cv <- mod$pred
  met_cv <- calcular_metricas_binarias(
    y_real = preds_cv$obs,
    y_pred = preds_cv$pred,
    prob_morcego = preds_cv$Morcego
  )
  met_cv$Preprocessamento <- prep_nome
  met_cv$Enriquecimento <- enr_nome
  met_cv$Melhor_size <- mod$bestTune$size
  met_cv$Melhor_decay <- mod$bestTune$decay

  res_ablacao_lista[[i]] <- met_cv
  cat(sprintf("  %-8s | %-18s | Sens=%.4f | Prec=%.4f | F1=%.4f | Acur=%.4f | AUC=%.4f\n",
              prep_nome, enr_nome, met_cv$Sensibilidade, met_cv$Precisao,
              met_cv$F1_score, met_cv$Acuracia, met_cv$ROC_AUC))
}

df_ablacao <- do.call(rbind, res_ablacao_lista)
df_ablacao <- df_ablacao[order(-df_ablacao$F1_score), ]
salvar_csv(df_ablacao, file.path(pasta_saida, "mlp_ablacao_enriquecimento.csv"))

melhor_prep <- df_ablacao$Preprocessamento[1]
melhor_enr <- df_ablacao$Enriquecimento[1]
cat(sprintf("\n-> Melhor combinação selecionada: Preprocessamento=%s | Enriquecimento=%s (F1=%.4f)\n",
            melhor_prep, melhor_enr, df_ablacao$F1_score[1]))

#-------------------------------------------------------------------------------
### 3B — Ajuste fino completo do MLP (mlpWeightDecay) com CV 5x5 + Holdout 20%

cat("\n[2/3] Executando ajuste fino (CV 5x5) do MLP com a melhor combinação...\n")

df_all_final <- montar_df(melhor_prep)
df_tr_final <- df_all_final[idx_treino, , drop = FALSE]
df_te_final <- df_all_final[idx_teste, , drop = FALSE]

sampling_final <- if (melhor_enr == "Sem_balanceamento") {
  NULL
} else if (melhor_enr == "Upsampling") {
  "up"
} else {
  smote_hook
}
preproc_final <- c("center", "scale")

grade_final <- expand.grid(
  size = c(5, 10, 20, 30),
  decay = c(0, 1e-5, 1e-4, 1e-3)
)

set.seed(2026)
ctrl_final <- caret::trainControl(
  method = "repeatedcv",
  number = 5,
  repeats = 5,
  classProbs = TRUE,
  summaryFunction = prSummary,
  sampling = sampling_final,
  savePredictions = "final"
)

modelo_final <- suppressWarnings(caret::train(
  Classe ~ .,
  data = df_tr_final,
  method = "mlpWeightDecay",
  metric = "F",
  preProcess = preproc_final,
  trControl = ctrl_final,
  tuneGrid = grade_final,
  maxit = 300
))

salvar_csv(modelo_final$results, file.path(pasta_saida, "mlp_grade_tuning.csv"))
saveRDS(modelo_final, file.path(pasta_saida, "modelo_mlp_final.rds"))

# Métricas CV 5x5 (agregadas por dobra para média e desvio-padrão)
preds_cv_final <- modelo_final$pred
dobras <- unique(preds_cv_final$Resample)
met_por_dobra <- do.call(rbind, lapply(dobras, function(d) {
  sub <- preds_cv_final[preds_cv_final$Resample == d, , drop = FALSE]
  calcular_metricas_binarias(sub$obs, sub$pred, sub$Morcego)
}))

# Avaliação no conjunto de treino (verificação de overfitting) e teste holdout (20%)
prob_tr <- predict(modelo_final, newdata = df_tr_final, type = "prob")[, "Morcego"]
pred_tr <- predict(modelo_final, newdata = df_tr_final, type = "raw")
met_treino <- calcular_metricas_binarias(df_tr_final$Classe, pred_tr, prob_tr)

prob_te <- predict(modelo_final, newdata = df_te_final, type = "prob")[, "Morcego"]
pred_te <- predict(modelo_final, newdata = df_te_final, type = "raw")
met_teste <- calcular_metricas_binarias(df_te_final$Classe, pred_te, prob_te)

#-------------------------------------------------------------------------------
### 3C — Predições Out-of-Fold (5 dobras) para todos os 8.426 organismos + Erros

cat("\n[3/3] Gerando predições Out-of-Fold (sem vazamento) para todos os 8.426 organismos...\n")
set.seed(2026)
folds_oof <- createFolds(y_fator, k = 5, list = TRUE)
prob_oof <- numeric(nrow(df_all_final))
pred_oof <- character(nrow(df_all_final))

ctrl_fixo <- caret::trainControl(
  method = "none",
  classProbs = TRUE,
  sampling = sampling_final
)

for (k in seq_along(folds_oof)) {
  va_i <- folds_oof[[k]]
  tr_i <- setdiff(seq_len(nrow(df_all_final)), va_i)
  set.seed(2026 + k)
  mod_k <- suppressWarnings(caret::train(
    Classe ~ .,
    data = df_all_final[tr_i, , drop = FALSE],
    method = "mlpWeightDecay",
    preProcess = preproc_final,
    trControl = ctrl_fixo,
    tuneGrid = modelo_final$bestTune,
    maxit = 300
  ))
  prob_oof[va_i] <- predict(mod_k, newdata = df_all_final[va_i, , drop = FALSE], type = "prob")[, "Morcego"]
  pred_oof[va_i] <- as.character(predict(mod_k, newdata = df_all_final[va_i, , drop = FALSE], type = "raw"))
}

met_oof <- calcular_metricas_binarias(y_fator, pred_oof, prob_oof)

df_oof <- data.frame(
  indice = base_sup$indice,
  nome_cientifico = base_sup$nome_cientifico,
  classe_real = base_sup$classe,
  classe_predita_oof = ifelse(pred_oof == "Morcego", 1L, 0L),
  prob_mlp_oof = round(prob_oof, 6),
  stringsAsFactors = FALSE
)
salvar_csv(df_oof, file.path(pasta_saida, "mlp_predicoes_oof.csv"))

# Tabela de análise de erros OOF (Falsos Positivos e Falsos Negativos)
erros_idx <- which(df_oof$classe_real != df_oof$classe_predita_oof)
if (length(erros_idx) > 0) {
  pos_reais <- which(base_sup$classe == 1L)
  dist_all <- distancia_cosseno_minima(dados$X_l2, pos_reais)
  df_erros <- df_oof[erros_idx, , drop = FALSE]
  df_erros$tipo_erro <- ifelse(df_erros$classe_predita_oof == 1L, "Falso Positivo (FP)", "Falso Negativo (FN)")
  df_erros$morcego_mais_proximo <- dados$nomes[dist_all$ref_mais_proximo[erros_idx]]
  df_erros$dist_cosseno <- round(dist_all$dist_min[erros_idx], 5)
} else {
  df_erros <- data.frame(
    indice = integer(0), nome_cientifico = character(0), classe_real = integer(0),
    classe_predita_oof = integer(0), prob_mlp_oof = numeric(0), tipo_erro = character(0),
    morcego_mais_proximo = character(0), dist_cosseno = numeric(0)
  )
}
salvar_csv(df_erros, file.path(pasta_saida, "mlp_analise_erros.csv"))

# Consolida tabela final de métricas
resumo_metricas <- rbind(
  data.frame(
    Avaliacao = "CV_5x5_media",
    Preprocessamento = melhor_prep,
    Enriquecimento = melhor_enr,
    size = modelo_final$bestTune$size,
    decay = modelo_final$bestTune$decay,
    VP = mean(met_por_dobra$VP),
    VN = mean(met_por_dobra$VN),
    FP = mean(met_por_dobra$FP),
    FN = mean(met_por_dobra$FN),
    Acuracia = mean(met_por_dobra$Acuracia),
    Sensibilidade = mean(met_por_dobra$Sensibilidade),
    Especificidade = mean(met_por_dobra$Especificidade),
    Precisao = mean(met_por_dobra$Precisao),
    F1_score = mean(met_por_dobra$F1_score),
    ROC_AUC = mean(met_por_dobra$ROC_AUC, na.rm = TRUE)
  ),
  data.frame(
    Avaliacao = "CV_5x5_desvio",
    Preprocessamento = melhor_prep,
    Enriquecimento = melhor_enr,
    size = modelo_final$bestTune$size,
    decay = modelo_final$bestTune$decay,
    VP = sd(met_por_dobra$VP),
    VN = sd(met_por_dobra$VN),
    FP = sd(met_por_dobra$FP),
    FN = sd(met_por_dobra$FN),
    Acuracia = sd(met_por_dobra$Acuracia),
    Sensibilidade = sd(met_por_dobra$Sensibilidade),
    Especificidade = sd(met_por_dobra$Especificidade),
    Precisao = sd(met_por_dobra$Precisao),
    F1_score = sd(met_por_dobra$F1_score),
    ROC_AUC = sd(met_por_dobra$ROC_AUC, na.rm = TRUE)
  ),
  cbind(data.frame(Avaliacao = "Treino_80pct", Preprocessamento = melhor_prep, Enriquecimento = melhor_enr,
                   size = modelo_final$bestTune$size, decay = modelo_final$bestTune$decay), met_treino),
  cbind(data.frame(Avaliacao = "Holdout_Teste_20pct", Preprocessamento = melhor_prep, Enriquecimento = melhor_enr,
                   size = modelo_final$bestTune$size, decay = modelo_final$bestTune$decay), met_teste),
  cbind(data.frame(Avaliacao = "OOF_8426_completo", Preprocessamento = melhor_prep, Enriquecimento = melhor_enr,
                   size = modelo_final$bestTune$size, decay = modelo_final$bestTune$decay), met_oof)
)

salvar_csv(resumo_metricas, file.path(pasta_saida, "mlp_metricas.csv"))

cat("\n========================================================================\n")
cat("  RESUMO FINAL — MLP (caret::mlpWeightDecay)\n")
cat("========================================================================\n")
cat(sprintf("Configuração ótima: prep=%s | enrich=%s | size=%d | decay=%.4f\n",
            melhor_prep, melhor_enr, modelo_final$bestTune$size, modelo_final$bestTune$decay))
cat(sprintf("Baseline majoritário (sempre 'Outro'): Acurácia = %.4f\n",
            1 - n_morcegos / nrow(base_sup)))
print(resumo_metricas[, c("Avaliacao", "Acuracia", "Sensibilidade", "Especificidade", "Precisao", "F1_score", "ROC_AUC")],
      row.names = FALSE, digits = 4)
cat(sprintf("\nErros OOF registrados: %d (salvos em resultados/mlp_analise_erros.csv)\n", nrow(df_erros)))

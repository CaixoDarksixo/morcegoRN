# João Gabriel Fanti
# João Victor Leal Gonçalves
# João Pedro Nossol
# Lucas Santana
# DS803 - Inteligência Computacional Aplicada I (UFPR)
# Etapa 4: Exportação dos entregáveis finais (item c) e geração das 4 figuras ggplot2

source(file.path("R", "00_setup.R"))

################################################################################
### ETAPA 4 - ENTREGÁVEIS FINAIS E FIGURAS PARA O RELATÓRIO E APRESENTAÇÃO
################################################################################

arq_base_final <- file.path(pasta_estado, "base_supervisionada.csv")
arq_historico <- file.path(pasta_estado, "historico_rodadas.csv")
arq_oof <- file.path(pasta_saida, "mlp_predicoes_oof.csv")
arq_ablacao <- file.path(pasta_saida, "mlp_ablacao_enriquecimento.csv")
arq_grade <- file.path(pasta_saida, "mlp_grade_tuning.csv")

if (!file.exists(arq_base_final)) {
  stop("Base supervisionada não encontrada. Finalize a Etapa 2 primeiro.")
}

dados <- carregar_dados()
base_sup <- read.csv(arq_base_final, stringsAsFactors = FALSE)
base_sup <- base_sup[order(base_sup$indice), ]
hist <- read.csv(arq_historico, stringsAsFactors = FALSE)

if (file.exists(arq_oof)) {
  df_oof <- read.csv(arq_oof, stringsAsFactors = FALSE)
  df_oof <- df_oof[order(df_oof$indice), ]
  prob_oof <- df_oof$prob_mlp_oof
  pred_oof <- df_oof$classe_predita_oof
} else {
  prob_oof <- rep(NA_real_, nrow(base_sup))
  pred_oof <- rep(NA_integer_, nrow(base_sup))
}

#-------------------------------------------------------------------------------
### Entregável (c): classificacao_final.csv (8.426 organismos) e indices_morcegos.txt

df_final <- data.frame(
  indice = base_sup$indice,
  nome_cientifico = base_sup$nome_cientifico,
  classe = base_sup$classe,
  prob_mlp_oof = prob_oof,
  classe_predita_oof = pred_oof,
  iteracao_descoberta = base_sup$iteracao_descoberta,
  origem = base_sup$origem,
  stringsAsFactors = FALSE
)
arq_csv_final <- file.path(pasta_saida, "classificacao_final.csv")
salvar_csv(df_final, arq_csv_final)

morcegos <- df_final[df_final$classe == 1L, , drop = FALSE]
morcegos <- morcegos[order(morcegos$indice), ]

arq_txt_indices <- file.path(pasta_saida, "indices_morcegos.txt")
linhas_txt <- c(
  "# DS803 - Reconhecimento de Padrões: É morcego?",
  sprintf("# Total de organismos analisados: %d", nrow(df_final)),
  sprintf("# Total de morcegos identificados (classe = 1): %d", nrow(morcegos)),
  "# Índices baseados em 1 (número da linha em Names.txt e wpc50.dat)",
  paste0("#", strrep("-", 72)),
  "# Lista compacta de índices positivos (1-based):",
  paste(morcegos$indice, collapse = ", "),
  paste0("#", strrep("-", 72)),
  sprintf("%-10s %-45s %s", "INDICE", "NOME_CIENTIFICO", "RODADA"),
  sprintf("%-10d %-45s %d", morcegos$indice, morcegos$nome_cientifico, morcegos$iteracao_descoberta)
)
writeLines(linhas_txt, arq_txt_indices, useBytes = FALSE)

cat("Entregável CSV salvo em:", arq_csv_final, "\n")
cat("Entregável TXT salvo em:", arq_txt_indices, sprintf("(%d morcegos)\n", nrow(morcegos)))

#-------------------------------------------------------------------------------
### Figura 1: PC1 vs PC2 com todos os morcegos identificados

df_pca <- data.frame(
  PC1 = dados$X[, 1],
  PC2 = dados$X[, 2],
  Classe = factor(ifelse(base_sup$classe == 1L, "Morcego (1)", "Outro (0)"),
                  levels = c("Outro (0)", "Morcego (1)"))
)

p1 <- ggplot(df_pca, aes(x = PC1, y = PC2)) +
  geom_point(data = subset(df_pca, Classe == "Outro (0)"),
             color = "#94a3b8", alpha = 0.25, size = 1.0) +
  geom_point(data = subset(df_pca, Classe == "Morcego (1)"),
             color = "#dc2626", alpha = 0.9, size = 2.3) +
  labs(
    title = "Projeção SWeeP-PCA (PC1 vs PC2) — Morcegos Identificados",
    subtitle = sprintf("8.426 organismos | %d morcegos (Chiroptera) em vermelho", nrow(morcegos)),
    x = "Componente Principal 1 (PC1)",
    y = "Componente Principal 2 (PC2)"
  ) +
  theme_minimal(base_size = 12)

ggsave(file.path(pasta_figuras, "fig1_pca_morcegos.png"), p1, width = 8.5, height = 5.5, dpi = 300)

#-------------------------------------------------------------------------------
### Figura 2: Curva de prospecção iterativa vs busca aleatória

max_q <- max(hist$acumulado_total)
total_m <- max(hist$acumulado_morcegos)
df_rand <- data.frame(
  consultas = seq(0, max_q, length.out = 50),
  esperado = seq(0, max_q, length.out = 50) * (total_m / nrow(df_final))
)

p2 <- ggplot() +
  geom_line(data = df_rand, aes(x = consultas, y = esperado, linetype = "Busca aleatória esperada"),
            color = "#94a3b8", linewidth = 0.9) +
  geom_line(data = hist, aes(x = acumulado_total, y = acumulado_morcegos, color = "Prospecção iterativa (MLP)"),
            linewidth = 1.2) +
  geom_point(data = hist, aes(x = acumulado_total, y = acumulado_morcegos),
             color = "#1d4ed8", size = 2.8) +
  geom_text(data = hist, aes(x = acumulado_total, y = acumulado_morcegos, label = paste0("R", rodada)),
            vjust = -1.0, size = 3.0, color = "#1e3a8a") +
  scale_color_manual(values = c("Prospecção iterativa (MLP)" = "#1d4ed8"), name = NULL) +
  scale_linetype_manual(values = c("Busca aleatória esperada" = "dashed"), name = NULL) +
  labs(
    title = "Curva de Descoberta Iterativa de Morcegos (Prospecção com MLP)",
    subtitle = sprintf("%d morcegos encontrados verificando apenas %d de 8.426 organismos (%.1f%%)",
                       total_m, max_q, 100 * max_q / nrow(df_final)),
    x = "Organismos verificados pelo oráculo (acumulado)",
    y = "Morcegos identificados (acumulado)"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

ggsave(file.path(pasta_figuras, "fig2_curva_prospeccao.png"), p2, width = 8.5, height = 5.2, dpi = 300)

#-------------------------------------------------------------------------------
### Figura 3: Enriquecimento da base e ajuste de hiperparâmetros do MLP

if (file.exists(arq_ablacao)) {
  df_ab <- read.csv(arq_ablacao, stringsAsFactors = FALSE)
  df_ab$Config <- paste(df_ab$Preprocessamento, "+", df_ab$Enriquecimento)
  df_ab_long <- rbind(
    data.frame(Config = df_ab$Config, Metrica = "Sensibilidade", Valor = df_ab$Sensibilidade),
    data.frame(Config = df_ab$Config, Metrica = "Precisão", Valor = df_ab$Precisao),
    data.frame(Config = df_ab$Config, Metrica = "F1-score", Valor = df_ab$F1_score)
  )

  p3 <- ggplot(df_ab_long, aes(x = reorder(Config, Valor), y = Valor, fill = Metrica)) +
    geom_col(position = position_dodge(width = 0.75), width = 0.7) +
    coord_flip(ylim = c(0.5, 1.0)) +
    scale_fill_manual(values = c("Sensibilidade" = "#2563eb", "Precisão" = "#16a34a", "F1-score" = "#dc2626")) +
    labs(
      title = "Impacto do Pré-processamento e Enriquecimento no MLP (CV)",
      subtitle = "Comparação de Z-score vs L2 e Sem balanceamento vs Upsampling vs SMOTE",
      x = NULL,
      y = "Pontuação Média",
      fill = "Métrica"
    ) +
    theme_minimal(base_size = 11.5) +
    theme(legend.position = "bottom")

  ggsave(file.path(pasta_figuras, "fig3_enriquecimento_mlp.png"), p3, width = 9.0, height = 5.2, dpi = 300)
}

if (file.exists(arq_grade)) {
  df_gr <- read.csv(arq_grade, stringsAsFactors = FALSE)
  p3b <- ggplot(df_gr, aes(x = factor(size), y = F, color = factor(decay), group = factor(decay))) +
    geom_line(linewidth = 1.1) +
    geom_point(size = 2.8) +
    labs(
      title = "Ajuste de Hiperparâmetros do MLP (caret::mlpWeightDecay)",
      subtitle = "F1-score médio na validação cruzada 5×5 por número de neurônios (size) e decay",
      x = "Neurônios na Camada Oculta (size)",
      y = "F1-score (CV 5×5)",
      color = "Regularização (decay)"
    ) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "bottom")

  ggsave(file.path(pasta_figuras, "fig3b_tuning_mlp.png"), p3b, width = 8.0, height = 5.0, dpi = 300)
}

#-------------------------------------------------------------------------------
### Figura 4: Matriz de Confusão e Curva ROC do MLP final (OOF)

if (file.exists(arq_oof)) {
  cm_tab <- as.data.frame(table(
    Real = factor(ifelse(df_oof$classe_real == 1L, "Morcego (1)", "Outro (0)"),
                  levels = c("Outro (0)", "Morcego (1)")),
    Predito = factor(ifelse(df_oof$classe_predita_oof == 1L, "Morcego (1)", "Outro (0)"),
                     levels = c("Outro (0)", "Morcego (1)"))
  ))

  p4_cm <- ggplot(cm_tab, aes(x = Predito, y = Real, fill = Freq)) +
    geom_tile(color = "white", linewidth = 1.2) +
    geom_text(aes(label = Freq), size = 6, fontface = "bold", color = "#111827") +
    scale_fill_gradient(low = "#eff6ff", high = "#3b82f6", guide = "none") +
    labs(
      title = "Matriz de Confusão do MLP Final (Predições Out-of-Fold — 8.426 organismos)",
      x = "Classe Predita",
      y = "Classe Real"
    ) +
    theme_minimal(base_size = 12)

  ggsave(file.path(pasta_figuras, "fig4a_matriz_confusao_mlp.png"), p4_cm, width = 6.5, height = 5.0, dpi = 300)

  roc_obj <- pROC::roc(
    response = factor(ifelse(df_oof$classe_real == 1L, "Morcego", "Outro"), levels = c("Outro", "Morcego")),
    predictor = df_oof$prob_mlp_oof,
    quiet = TRUE
  )
  auc_val <- as.numeric(pROC::auc(roc_obj))
  df_roc <- data.frame(
    FPR = 1 - roc_obj$specificities,
    TPR = roc_obj$sensitivities
  )

  p4_roc <- ggplot(df_roc, aes(x = FPR, y = TPR)) +
    geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "#94a3b8") +
    geom_line(color = "#1d4ed8", linewidth = 1.2) +
    labs(
      title = sprintf("Curva ROC do MLP Final (ROC-AUC = %.4f)", auc_val),
      x = "Taxa de Falsos Positivos (1 − Especificidade)",
      y = "Sensibilidade (Taxa de Verdadeiros Positivos)"
    ) +
    theme_minimal(base_size = 12)

  ggsave(file.path(pasta_figuras, "fig4b_curva_roc_mlp.png"), p4_roc, width = 6.8, height = 5.2, dpi = 300)
}

cat("Figuras geradas em:", pasta_figuras, "\n")

# João Gabriel Fanti
# João Victor Leal Gonçalves
# João Pedro Nossol
# Lucas Santana
# DS803 - Inteligência Computacional Aplicada I (UFPR)
# Etapa 1: Carregamento, validação, estatísticas descritivas e visualização PCA

source(file.path("R", "00_setup.R"))

################################################################################
### ETAPA 1 - CARREGAMENTO E EXPLORAÇÃO INICIAL DOS DADOS
################################################################################

dados <- carregar_dados()
sementes <- obter_sementes_iniciais(dados$nomes)

normas_l2 <- sqrt(rowSums(dados$X^2))
desvios_pc <- apply(dados$X, 2, sd)

cat("========================================================================\n")
cat("  ETAPA 1 — Caracterização dos dados SWeeP-PCA50 (wpc50.dat / Names.txt)\n")
cat("========================================================================\n")
cat(sprintf("Total de organismos: %d | Características (PCs): %d\n",
            nrow(dados$X), ncol(dados$X)))
cat(sprintf("Valores NA / não finitos: %d\n", sum(!is.finite(dados$X))))
cat(sprintf("Norma L2 — min: %.4f | mediana: %.4f | média: %.4f | max: %.4f\n",
            min(normas_l2), median(normas_l2), mean(normas_l2), max(normas_l2)))
cat("Desvio-padrão PC01..PC05:", paste(round(desvios_pc[1:5], 4), collapse = ", "), "\n")
cat("Desvio-padrão PC46..PC50:", paste(round(desvios_pc[46:50], 4), collapse = ", "), "\n")

resumo_dados <- data.frame(
  Total_organismos = nrow(dados$X),
  Total_caracteristicas = ncol(dados$X),
  Norma_L2_min = min(normas_l2),
  Norma_L2_mediana = median(normas_l2),
  Norma_L2_media = mean(normas_l2),
  Norma_L2_max = max(normas_l2),
  SD_PC01 = desvios_pc[1],
  SD_PC02 = desvios_pc[2],
  SD_PC50 = desvios_pc[50]
)
salvar_csv(resumo_dados, file.path(pasta_saida, "etapa1_resumo_dados.csv"))

# Verifica vizinhos cosseno mais próximos de duas sementes de morcego (sanidade)
cat("\nVizinhos mais próximos (distância cosseno) de duas sementes de morcego:\n")
for (ref_nome in c("Myotis_bechsteinii", "Pteropus_alecto")) {
  ref_idx <- match(ref_nome, dados$nomes)
  d_ref <- distancia_cosseno_minima(dados$X_l2, ref_idx)$dist_min
  ordem <- order(d_ref)
  ordem <- ordem[ordem != ref_idx][1:6]
  cat(sprintf("  #%d %s -> %s\n", ref_idx, ref_nome,
              paste(sprintf("%s (%.3f)", dados$nomes[ordem], d_ref[ordem]), collapse = ", ")))
}

#-------------------------------------------------------------------------------
### Figura 1 (preliminar): Projeção PC1 vs PC2 com sementes iniciais

df_pca <- data.frame(
  PC1 = dados$X[, 1],
  PC2 = dados$X[, 2],
  Grupo = "Não rotulado",
  stringsAsFactors = FALSE
)
df_pca$Grupo[sementes$indice[sementes$classe == 0L]] <- "Semente Não-Morcego"
df_pca$Grupo[sementes$indice[sementes$classe == 1L]] <- "Semente Morcego"
df_pca$Grupo <- factor(
  df_pca$Grupo,
  levels = c("Não rotulado", "Semente Não-Morcego", "Semente Morcego")
)

p_pca <- ggplot(df_pca, aes(x = PC1, y = PC2)) +
  geom_point(
    data = subset(df_pca, Grupo == "Não rotulado"),
    color = "#94a3b8", alpha = 0.28, size = 1.0
  ) +
  geom_point(
    data = subset(df_pca, Grupo == "Semente Não-Morcego"),
    aes(color = Grupo), size = 2.4, alpha = 0.9
  ) +
  geom_point(
    data = subset(df_pca, Grupo == "Semente Morcego"),
    aes(color = Grupo), size = 3.0, alpha = 0.95
  ) +
  scale_color_manual(
    values = c(
      "Semente Não-Morcego" = "#2563eb",
      "Semente Morcego" = "#dc2626"
    ),
    name = "Sementes (Rodada 0)"
  ) +
  labs(
    title = "Projeção SWeeP-PCA (PC1 vs PC2) — 8.426 Genomas Mitocondriais",
    subtitle = "Posição das sementes iniciais (10 morcegos de ambas as subordens e 39 não-morcegos)",
    x = "Componente Principal 1 (PC1)",
    y = "Componente Principal 2 (PC2)"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

arq_fig1 <- file.path(pasta_figuras, "fig1_pca_morcegos.png")
ggsave(arq_fig1, plot = p_pca, width = 8.5, height = 5.5, dpi = 300)

cat("\nResumo salvo em:", file.path(pasta_saida, "etapa1_resumo_dados.csv"), "\n")
cat("Figura 1 (preliminar) salva em:", arq_fig1, "\n")

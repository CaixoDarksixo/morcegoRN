# João Gabriel Fanti
# João Victor Leal Gonçalves
# João Pedro Nossol
# Lucas Santana
# DS803 - Inteligência Computacional Aplicada I (UFPR)
# Etapa 2: Supervisão e Prospecção Iterativa de Morcegos com MLP (caret + mlpWeightDecay)
#
# Uso no terminal:
#   Rscript R/02_prospeccao_mlp.R               # Loop interativo contínuo (auto-inicializa sementes)
#   Rscript R/02_prospeccao_mlp.R --status      # Mostra progresso e histórico de rodadas
#   Rscript R/02_prospeccao_mlp.R --init        # Apenas inicializa as sementes (Rodada 0)
#   Rscript R/02_prospeccao_mlp.R --rodada      # Executa uma única rodada interativa
#   Rscript R/02_prospeccao_mlp.R --varredura   # Varredura de sanidade por vizinhos cosseno
#   Rscript R/02_prospeccao_mlp.R --finalizar   # Congela os 8.426 rótulos em estado/base_supervisionada.csv

source(file.path("R", "00_setup.R"))

arq_rotulos <- file.path(pasta_estado, "rotulos_oraculo.csv")
arq_historico <- file.path(pasta_estado, "historico_rodadas.csv")
arq_base_final <- file.path(pasta_estado, "base_supervisionada.csv")

#-------------------------------------------------------------------------------
### Persistência de estado (retomável a qualquer momento)

carregar_rotulos <- function() {
  if (!file.exists(arq_rotulos)) {
    return(data.frame(
      indice = integer(0),
      nome_cientifico = character(0),
      classe = integer(0),
      rodada = integer(0),
      origem = character(0),
      motivo = character(0),
      prob_mlp = numeric(0),
      morcego_mais_proximo = character(0),
      dist_cosseno = numeric(0),
      stringsAsFactors = FALSE
    ))
  }
  read.csv(arq_rotulos, stringsAsFactors = FALSE)
}

carregar_historico <- function() {
  if (!file.exists(arq_historico)) {
    return(data.frame(
      rodada = integer(0),
      tipo = character(0),
      consultados = integer(0),
      novos_morcegos = integer(0),
      novos_outros = integer(0),
      acumulado_morcegos = integer(0),
      acumulado_total = integer(0),
      stringsAsFactors = FALSE
    ))
  }
  read.csv(arq_historico, stringsAsFactors = FALSE)
}

inicializar_sementes <- function(dados) {
  rotulos <- carregar_rotulos()
  if (nrow(rotulos) > 0) return(FALSE)

  sementes <- obter_sementes_iniciais(dados$nomes)
  df_init <- data.frame(
    indice = sementes$indice,
    nome_cientifico = sementes$nome,
    classe = sementes$classe,
    rodada = 0L,
    origem = "semente_literatura",
    motivo = ifelse(sementes$classe == 1L, "semente_pos", "semente_neg"),
    prob_mlp = NA_real_,
    morcego_mais_proximo = NA_character_,
    dist_cosseno = NA_real_,
    stringsAsFactors = FALSE
  )
  salvar_csv(df_init, arq_rotulos)

  hist_init <- data.frame(
    rodada = 0L,
    tipo = "sementes",
    consultados = nrow(df_init),
    novos_morcegos = sum(df_init$classe == 1L),
    novos_outros = sum(df_init$classe == 0L),
    acumulado_morcegos = sum(df_init$classe == 1L),
    acumulado_total = nrow(df_init),
    stringsAsFactors = FALSE
  )
  salvar_csv(hist_init, arq_historico)
  TRUE
}

rodadas_consecutivas_zero <- function(hist) {
  ativas <- hist[hist$tipo == "rodada_mlp" & hist$consultados > 0, , drop = FALSE]
  if (nrow(ativas) == 0) return(0L)
  cont <- 0L
  for (i in rev(seq_len(nrow(ativas)))) {
    if (ativas$novos_morcegos[i] == 0L) cont <- cont + 1L else break
  }
  cont
}

exibir_status <- function() {
  rot <- carregar_rotulos()
  hist <- carregar_historico()
  cat("\n========================================================================\n")
  cat("  STATUS DA PROSPECÇÃO ITERATIVA (MLP + caret)\n")
  cat("========================================================================\n")
  cat(sprintf("Total verificado pelo oráculo: %d / 8426\n", nrow(rot)))
  cat(sprintf("  - Morcegos confirmados (1):     %d\n", sum(rot$classe == 1L)))
  cat(sprintf("  - Não-morcegos confirmados (0): %d\n", sum(rot$classe == 0L)))
  cat(sprintf("Rodadas consecutivas com 0 novos morcegos: %d\n", rodadas_consecutivas_zero(hist)))
  cat(sprintf("Base supervisionada finalizada? %s\n", ifelse(file.exists(arq_base_final), "SIM", "NÃO")))
  if (nrow(hist) > 0) {
    cat("\nHistórico de rodadas:\n")
    print(hist, row.names = FALSE)
  }
  cat("========================================================================\n")
}

#-------------------------------------------------------------------------------
### Pontuação dos organismos não rotulados usando caret + mlpWeightDecay

pontuar_com_mlp <- function(dados, rotulos, semente = 2026) {
  set.seed(semente)
  idx_rot <- rotulos$indice
  y_rot <- factor(
    ifelse(rotulos$classe == 1L, "Morcego", "Outro"),
    levels = c("Morcego", "Outro")
  )

  # Usa vetores L2-normalizados para o MLP de prospecção + upsampling nas dobras
  df_treino <- as.data.frame(dados$X_l2[idx_rot, , drop = FALSE])
  df_treino$Classe <- y_rot

  n_folds <- min(5L, sum(rotulos$classe == 1L))
  ctrl <- caret::trainControl(
    method = "cv",
    number = max(3L, n_folds),
    classProbs = TRUE,
    summaryFunction = prSummary,
    sampling = "up",
    allowParallel = FALSE
  )

  # Em RSNNS::mlpWeightDecay, valores de decay devem ser pequenos (0 a 1e-3)
  grade <- expand.grid(
    size = c(5, 10, 16),
    decay = c(1e-5, 1e-4, 1e-3)
  )

  modelo <- suppressWarnings(caret::train(
    Classe ~ .,
    data = df_treino,
    method = "mlpWeightDecay",
    metric = "F",
    preProcess = c("center", "scale"),
    trControl = ctrl,
    tuneGrid = grade,
    maxit = 300
  ))

  probs <- predict(modelo, newdata = as.data.frame(dados$X_l2), type = "prob")[, "Morcego"]
  list(probs = as.numeric(probs), modelo = modelo)
}

selecionar_lote_candidatos <- function(dados, rotulos, probs, k_alta = 15L, k_fronteira = 5L) {
  nao_rotulados <- setdiff(dados$indices, rotulos$indice)
  if (length(nao_rotulados) == 0) return(NULL)

  idx_pos <- rotulos$indice[rotulos$classe == 1L]
  dist_info <- distancia_cosseno_minima(dados$X_l2, idx_pos)

  # 1) Top k_alta por maior probabilidade P(Morcego)
  ord_alta <- nao_rotulados[order(-probs[nao_rotulados])]
  pick_alta <- head(ord_alta, k_alta)

  # 2) Top k_fronteira por maior incerteza (|P(Morcego) - 0.5| mais próximo de 0)
  restantes <- setdiff(nao_rotulados, pick_alta)
  ord_front <- restantes[order(abs(probs[restantes] - 0.5))]
  pick_front <- head(ord_front, k_fronteira)

  escolhidos <- c(pick_alta, pick_front)
  motivos <- c(rep("alta", length(pick_alta)), rep("fronteira", length(pick_front)))

  data.frame(
    indice = escolhidos,
    nome_cientifico = dados$nomes[escolhidos],
    motivo = motivos,
    prob_mlp = probs[escolhidos],
    morcego_mais_proximo = dados$nomes[dist_info$ref_mais_proximo[escolhidos]],
    dist_cosseno = dist_info$dist_min[escolhidos],
    stringsAsFactors = FALSE
  )
}

#-------------------------------------------------------------------------------
### Interface interativa no console R

ler_linha_console <- function(prompt_texto) {
  if (interactive()) {
    linha <- readline(prompt = prompt_texto)
  } else {
    cat(prompt_texto)
    flush.console()
    con <- file("stdin")
    linha <- readLines(con, n = 1)
    close(con)
  }
  if (length(linha) == 0) return("q")
  tolower(trimws(linha))
}

rotular_lote_interativo <- function(lote, rodada, origem = "oraculo_cli") {
  cat("\n==================================================================================================\n")
  cat(sprintf("  RODADA %d — Lote proposto pelo MLP (%d candidatos)\n", rodada, nrow(lote)))
  cat("==================================================================================================\n")
  cat(sprintf("%2s | %6s | %-34s | %-9s | %7s | %-28s\n",
              "#", "Idx(1)", "Nome Científico", "Motivo", "P(Morc)", "Morcego +próximo (dist)"))
  cat("--------------------------------------------------------------------------------------------------\n")
  for (i in seq_len(nrow(lote))) {
    nb_txt <- sprintf("%-20s (%.3f)", substr(lote$morcego_mais_proximo[i], 1, 20), lote$dist_cosseno[i])
    cat(sprintf("%2d | %6d | %-34s | %-9s | %7.3f | %s\n",
                i, lote$indice[i], substr(lote$nome_cientifico[i], 1, 34),
                lote$motivo[i], lote$prob_mlp[i], nb_txt))
  }
  cat("--------------------------------------------------------------------------------------------------\n")
  cat("Comandos: [1/s] Morcego | [0/n] Outro | [all1] Restantes=1 | [all0] Restantes=0 | [u] Desfazer | [skip] Pular | [q] Salvar e sair\n")

  respostas <- rep(NA_integer_, nrow(lote))
  decidido <- rep(FALSE, nrow(lote))
  i <- 1L
  sair <- FALSE

  while (i <= nrow(lote)) {
    prompt_txt <- sprintf(
      "  [%d/%d] #%d %s (motivo=%s, P=%.3f) -> É morcego? [1/0/u/skip/all1/all0/q]: ",
      i, nrow(lote), lote$indice[i], lote$nome_cientifico[i], lote$motivo[i], lote$prob_mlp[i]
    )
    ans <- ler_linha_console(prompt_txt)

    if (ans %in% c("1", "s", "sim", "y", "yes", "m")) {
      respostas[i] <- 1L
      decidido[i] <- TRUE
      i <- i + 1L
    } else if (ans %in% c("0", "n", "nao", "não", "no")) {
      respostas[i] <- 0L
      decidido[i] <- TRUE
      i <- i + 1L
    } else if (ans == "skip") {
      respostas[i] <- NA_integer_
      decidido[i] <- FALSE
      i <- i + 1L
    } else if (ans == "all1") {
      respostas[i:nrow(lote)] <- 1L
      decidido[i:nrow(lote)] <- TRUE
      break
    } else if (ans == "all0") {
      respostas[i:nrow(lote)] <- 0L
      decidido[i:nrow(lote)] <- TRUE
      break
    } else if (ans == "u") {
      if (i > 1L) {
        i <- i - 1L
        respostas[i] <- NA_integer_
        decidido[i] <- FALSE
        cat(sprintf("    ↩ Desfeito: #%d %s\n", lote$indice[i], lote$nome_cientifico[i]))
      } else {
        cat("    (Nada para desfazer nesta rodada.)\n")
      }
    } else if (ans %in% c("q", "quit", "sair")) {
      sair <- TRUE
      break
    } else {
      cat("    Entrada inválida. Use 1, 0, all1, all0, u, skip ou q.\n")
    }
  }

  validos <- which(decidido & !is.na(respostas))
  if (length(validos) == 0) {
    return(list(novos = NULL, sair = sair))
  }

  novos <- data.frame(
    indice = lote$indice[validos],
    nome_cientifico = lote$nome_cientifico[validos],
    classe = respostas[validos],
    rodada = as.integer(rodada),
    origem = origem,
    motivo = lote$motivo[validos],
    prob_mlp = round(lote$prob_mlp[validos], 6),
    morcego_mais_proximo = lote$morcego_mais_proximo[validos],
    dist_cosseno = round(lote$dist_cosseno[validos], 6),
    stringsAsFactors = FALSE
  )
  list(novos = novos, sair = sair)
}

executar_rodada <- function(dados, k_alta = 15L, k_fronteira = 5L) {
  rotulos <- carregar_rotulos()
  hist <- carregar_historico()
  prox_rodada <- if (nrow(hist) == 0) 1L else max(hist$rodada) + 1L

  cat(sprintf("\nTreinando MLP (mlpWeightDecay) na base atual (%d rotulados, %d morcegos)...\n",
              nrow(rotulos), sum(rotulos$classe == 1L)))
  res_mlp <- pontuar_com_mlp(dados, rotulos, semente = 2026L + prox_rodada)
  lote <- selecionar_lote_candidatos(dados, rotulos, res_mlp$probs, k_alta, k_fronteira)
  if (is.null(lote) || nrow(lote) == 0) {
    cat("Não há mais instâncias não rotuladas.\n")
    return(TRUE)
  }

  resp <- rotular_lote_interativo(lote, rodada = prox_rodada, origem = "oraculo_cli")
  if (!is.null(resp$novos)) {
    rotulos_atual <- rbind(rotulos, resp$novos)
    rotulos_atual <- rotulos_atual[!duplicated(rotulos_atual$indice, fromLast = TRUE), ]
    rotulos_atual <- rotulos_atual[order(rotulos_atual$indice), ]
    salvar_csv(rotulos_atual, arq_rotulos)

    nova_linha <- data.frame(
      rodada = prox_rodada,
      tipo = "rodada_mlp",
      consultados = nrow(resp$novos),
      novos_morcegos = sum(resp$novos$classe == 1L),
      novos_outros = sum(resp$novos$classe == 0L),
      acumulado_morcegos = sum(rotulos_atual$classe == 1L),
      acumulado_total = nrow(rotulos_atual),
      stringsAsFactors = FALSE
    )
    salvar_csv(rbind(hist, nova_linha), arq_historico)
    cat(sprintf("\nRodada %d salva: +%d morcegos, +%d outros (acumulado: %d morcegos).\n",
                prox_rodada, nova_linha$novos_morcegos, nova_linha$novos_outros,
                nova_linha$acumulado_morcegos))
  }
  resp$sair
}

executar_varredura_sanidade <- function(dados, top_n = 20L) {
  rotulos <- carregar_rotulos()
  hist <- carregar_historico()
  prox_rodada <- if (nrow(hist) == 0) 1L else max(hist$rodada) + 1L

  nao_rotulados <- setdiff(dados$indices, rotulos$indice)
  idx_pos <- rotulos$indice[rotulos$classe == 1L]
  dist_info <- distancia_cosseno_minima(dados$X_l2, idx_pos)
  res_mlp <- pontuar_com_mlp(dados, rotulos, semente = 2026L + prox_rodada)

  ord <- nao_rotulados[order(dist_info$dist_min[nao_rotulados])]
  escolhidos <- head(ord, top_n)

  lote <- data.frame(
    indice = escolhidos,
    nome_cientifico = dados$nomes[escolhidos],
    motivo = "varredura",
    prob_mlp = res_mlp$probs[escolhidos],
    morcego_mais_proximo = dados$nomes[dist_info$ref_mais_proximo[escolhidos]],
    dist_cosseno = dist_info$dist_min[escolhidos],
    stringsAsFactors = FALSE
  )

  cat("\n>>> VARREDURA DE SANIDADE — Top-20 organismos não rotulados mais próximos aos morcegos <<<\n")
  resp <- rotular_lote_interativo(lote, rodada = prox_rodada, origem = "varredura_sanidade")
  if (!is.null(resp$novos)) {
    rotulos_atual <- rbind(rotulos, resp$novos)
    rotulos_atual <- rotulos_atual[!duplicated(rotulos_atual$indice, fromLast = TRUE), ]
    rotulos_atual <- rotulos_atual[order(rotulos_atual$indice), ]
    salvar_csv(rotulos_atual, arq_rotulos)

    nova_linha <- data.frame(
      rodada = prox_rodada,
      tipo = "varredura",
      consultados = nrow(resp$novos),
      novos_morcegos = sum(resp$novos$classe == 1L),
      novos_outros = sum(resp$novos$classe == 0L),
      acumulado_morcegos = sum(rotulos_atual$classe == 1L),
      acumulado_total = nrow(rotulos_atual),
      stringsAsFactors = FALSE
    )
    salvar_csv(rbind(hist, nova_linha), arq_historico)
    cat(sprintf("\nVarredura salva: +%d morcegos, +%d outros.\n",
                nova_linha$novos_morcegos, nova_linha$novos_outros))
  }
}

finalizar_base <- function(dados) {
  rotulos <- carregar_rotulos()
  base_df <- data.frame(
    indice = dados$indices,
    nome_cientifico = dados$nomes,
    classe = 0L,
    iteracao_descoberta = -1L,
    origem = "nao_consultado_default",
    stringsAsFactors = FALSE
  )
  pos <- match(rotulos$indice, base_df$indice)
  base_df$classe[pos] <- rotulos$classe
  base_df$iteracao_descoberta[pos] <- rotulos$rodada
  base_df$origem[pos] <- rotulos$origem

  salvar_csv(base_df, arq_base_final)
  cat(sprintf("\nBase supervisionada final salva em: %s\n", arq_base_final))
  cat(sprintf("Total: %d organismos | Morcegos (1): %d | Outros (0): %d | Verificados no oráculo: %d\n",
              nrow(base_df), sum(base_df$classe == 1L), sum(base_df$classe == 0L), nrow(rotulos)))
}

#-------------------------------------------------------------------------------
### Execução CLI

executar_cli <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  dados <- carregar_dados()

  if (inicializar_sementes(dados)) {
    cat("Rodada 0 inicializada: 10 sementes de morcego (2 subordens) + 39 não-morcegos.\n")
  }

  if ("--status" %in% args || "--init" %in% args) {
    exibir_status()
    return(invisible(NULL))
  }
  if ("--rodada" %in% args) {
    executar_rodada(dados)
    exibir_status()
    return(invisible(NULL))
  }
  if ("--varredura" %in% args) {
    executar_varredura_sanidade(dados)
    exibir_status()
    return(invisible(NULL))
  }
  if ("--finalizar" %in% args) {
    finalizar_base(dados)
    exibir_status()
    return(invisible(NULL))
  }

  # Loop interativo contínuo
  exibir_status()
  repeat {
    hist <- carregar_historico()
    if (rodadas_consecutivas_zero(hist) >= 2L) {
      cat("\nCritério de convergência atingido (2 rodadas consecutivas com 0 novos morcegos)!\n")
      op <- ler_linha_console("Escolha: [v] varredura de sanidade | [f] finalizar base | [r] nova rodada | [q] sair: ")
      if (op == "v") {
        executar_varredura_sanidade(dados)
        exibir_status()
        next
      } else if (op == "f") {
        finalizar_base(dados)
        break
      } else if (op == "q") {
        break
      }
    }

    sair <- executar_rodada(dados)
    if (isTRUE(sair)) {
      cat("Sessão encerrada com progresso salvo em estado/.\n")
      break
    }

    op <- ler_linha_console("\nPróximo passo [Enter=próxima rodada | s=status | v=varredura | f=finalizar | q=sair]: ")
    if (op == "s") {
      exibir_status()
    } else if (op == "v") {
      executar_varredura_sanidade(dados)
      exibir_status()
    } else if (op == "f") {
      finalizar_base(dados)
      break
    } else if (op == "q") {
      cat("Progresso salvo em estado/. Até a próxima!\n")
      break
    }
  }
}

#-------------------------------------------------------------------------------
### Atalhos práticos para uso direto no Console do RStudio
# Basta rodar source("R/02_prospeccao_mlp.R") no RStudio e depois chamar:
#   rodada_mlp()            -> executa 1 rodada interativa (20 candidatos)
#   ver_status()            -> mostra progresso e histórico
#   varredura_sanidade()    -> verifica top-20 vizinhos cosseno mais próximos
#   finalizar_prospeccao()  -> congela os 8.426 rótulos em estado/base_supervisionada.csv

rodada_mlp <- function(k_alta = 15L, k_fronteira = 5L) {
  dados <- carregar_dados()
  inicializar_sementes(dados)
  executar_rodada(dados, k_alta = k_alta, k_fronteira = k_fronteira)
  exibir_status()
}

ver_status <- function() {
  dados <- carregar_dados()
  inicializar_sementes(dados)
  exibir_status()
}

varredura_sanidade <- function(top_n = 20L) {
  dados <- carregar_dados()
  inicializar_sementes(dados)
  executar_varredura_sanidade(dados, top_n = top_n)
  exibir_status()
}

finalizar_prospeccao <- function() {
  dados <- carregar_dados()
  inicializar_sementes(dados)
  finalizar_base(dados)
  exibir_status()
}

if (sys.nframe() == 0) {
  executar_cli()
} else if (interactive()) {
  dados_init <- carregar_dados()
  inicializar_sementes(dados_init)
  exibir_status()
  cat("\nComandos disponíveis no Console do RStudio:\n")
  cat("  rodada_mlp()            # Executar próxima rodada interativa (15 alta + 5 fronteira)\n")
  cat("  ver_status()            # Ver resumo e histórico das rodadas\n")
  cat("  varredura_sanidade()    # Conferir top-20 vizinhos mais próximos aos morcegos\n")
  cat("  finalizar_prospeccao()  # Congelar todos os 8.426 rótulos para a Etapa 3\n")
}

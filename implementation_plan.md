# Implementation Plan (R + `caret` + MLP) — "É morcego?"

Simplified, focused plan for [Trabalho_morcegos.pdf](./Trabalho_morcegos.pdf) using **R**, **`caret`**, and **MLP** (DS803 – Inteligência Computacional Aplicada I, UFPR).

---

## 1. Goal & Approach

Identify all bats (order *Chiroptera*) among the **8,426 organisms** in [wpc50.dat](./wpc50.dat) (50 SWeeP-PCA mitochondrial features) and [Names.txt](./Names.txt) (scientific names, 1-based line order — R's native indexing) through a **simple, reproducible R workflow**:

1. **Explore** the data briefly (summary stats + PC1 vs. PC2 plot).
2. **Prospect iteratively** starting from a small set of known bat & non-bat seeds, using an **MLP (`caret`)** in successive rounds + interactive console verification (`1` = Morcego, `0` = Outro) until no new bats appear.
3. **Enrich** the training set cleanly (hard negatives discovered during prospecting + `caret`'s built-in class-imbalance resampling, e.g., `sampling = "up"` or `"smote"` vs. raw).
4. **Benchmark & evaluate the MLP** using `caret` (`method = "mlp"` / `"mlpWeightDecay"` via `RSNNS`) with cross-validation and an 80/20 holdout split, reporting **Sensibilidade, Precisão, Acurácia**, plus **Especificidade** and **F1-score**.
5. **Export deliverables** (all 8,426 labels, ordered 1-based bat indices, figures, and report/slide draft).

---

## 2. Project Structure (Lean)

```text
/home/joao/Projects/IA/
├── Names.txt                       # Raw input (8,426 names, 1-based)
├── wpc50.dat                       # Raw input (8,426 x 50 PCs)
├── Trabalho_morcegos.pdf           # Assignment specification
├── R/
│   ├── 00_setup.R                  # Pacotes (caret, RSNNS, ggplot2, pROC, smotefamily), utilitários e sementes
│   ├── 01_exploracao.R             # Carregamento, estatísticas básicas e Figura 1 (PC1 vs PC2)
│   ├── 02_prospeccao_mlp.R         # Sementes + prospecção iterativa interativa com MLP (mlpWeightDecay)
│   ├── 03_benchmark_mlp.R          # Ablação (Raw/Up/SMOTE, Z-score/L2), tuning CV 5x5 e holdout 80/20
│   └── 04_exportar_resultados.R    # Exporta classificacao_final.csv, indices_morcegos.txt e figuras ggplot2
├── estado/
│   ├── rotulos_oraculo.csv         # Rótulos verificados por rodada (retomável)
│   ├── historico_rodadas.csv       # Morcegos encontrados e consultas por rodada
│   └── base_supervisionada.csv     # Base final congelada (8.426 organismos)
└── resultados/
    ├── classificacao_final.csv     # 8.426 linhas: indice, nome_cientifico, classe (1/0), prob_mlp_oof
    ├── indices_morcegos.txt        # Índices 1-based ordenados e nomes dos morcegos
    ├── mlp_metricas.csv            # Métricas finais (CV 5x5, treino, holdout 20%, OOF)
    └── figuras/                    # Gráficos ggplot2 em português (300 DPI)
```

---

## 3. R Environment & Packages

System has **R 4.5.0** installed (`/usr/bin/Rscript`). Minimal packages needed:
- `caret` — unified training, preprocessing, resampling, CV, tuning, and `confusionMatrix()`
- `RSNNS` — backend for `caret` `method = "mlp"` / `"mlpWeightDecay"`
- `ggplot2` — clean plots for the report and 10-minute presentation
- `pROC` — ROC curve & AUC (optional `themis` only if we want SMOTE alongside `caret`'s built-in `"up"`/`"down"`)

---

## 4. Step-by-Step Pipeline

### Step 1 — Data Loading & Quick Exploration (`R/01_load_eda.R`)
- Read `wpc50.dat` via `read.table()` into an `8426 × 50` numeric matrix and `Names.txt` via `trimws(readLines())`.
- Verify zero `NA`/non-finite values and 1-to-1 alignment (`indice = 1:8426`).
- Print basic feature statistics (ranges, L2 norms) and generate **Figure 1**: PC1 vs. PC2 scatter plot highlighting the initial seeds (and updated later with all discovered bats).

### Step 2 — Supervision & Iterative MLP Prospecting (`R/02_prospect_mlp.R`)
*Covers criteria **(a)** and **(b)** without overengineering.*

```text
[Round 0: Seeds] ──▶ [Train MLP (caret)] ──▶ [Rank Unlabeled by P(Morcego)]
        ▲                                                 │
        │                                                 ▼
[Append to CSV] ◀── [Verify Batch in R Console (1/0)] ◀── [Top-15 High Prob + Top-5 Borderline (p≈0.5)]
        │
        └── Stop when 2 consecutive rounds find 0 new bats (+ nearest-neighbor sanity check)
```

1. **Round 0 (Seeds)**:
   - **10 known bats** spanning both suborders (*Yinpterochiroptera*: `Pteropus_alecto`, `Cynopterus_brachyotis`, `Rousettus_aegyptiacus`, `Rhinolophus_formosae`, `Hipposideros_armiger`; *Yangochiroptera*: `Myotis_bechsteinii`, `Artibeus_jamaicensis`, `Desmodus_rotundus`, `Pipistrellus_abramus`, `Tadarida_teniotis`).
   - **~35–40 known non-bats** covering fungi, fish, birds, reptiles, insects, and diverse non-bat mammals (primates, rodents, carnivores, ungulates, shrews/moles).
2. **Each Round `t = 1, 2, ...`**:
   - Train a fast `caret` MLP (`method = "mlp"`, `preProcess = c("center", "scale")` or L2-normalized rows, `sampling = "up"`) on all labels verified so far.
   - Predict `P(Morcego)` for all unlabeled organisms.
   - Propose a small batch of **20 candidates**:
     - **15 highest probability** (`P(Morcego)` descending) — finds new bats rapidly.
     - **5 most uncertain** (`|P(Morcego) - 0.5|` ascending) — finds borderline bats and **hard negatives** (close non-bat mammals) that sharpen the MLP boundary.
   - Prompt interactively in the R console (`1` = Morcego, `0` = Outro, `all1`/`all0`, `q` = save & exit anytime). Every answer is saved immediately to `state/labels_log.csv` so sessions are fully resumable.
3. **Stopping & Sanity Check**:
   - Stop when **2 consecutive rounds yield 0 new bats**.
   - Run one final **Euclidean/cosine nearest-neighbor sanity check** (checking the closest 20 unlabeled organisms to all confirmed bats) to be sure no bat was missed.
   - Assign `0` (Outro) to all remaining unqueried organisms → complete 8,426-row supervised dataset.

### Step 3 — Training Set Enrichment & MLP Benchmark (`R/03_train_eval_mlp.R`)
*Covers criteria **(b), (d), (e)** — focused strictly on **MLP via `caret`**.*

1. **Train / Test Split**: Stratified 80% train / 20% holdout test via `caret::createDataPartition(y, p = 0.80, list = FALSE)`.
2. **Enrichment Comparison (Inside CV Folds Only)**:
   - Compare MLP with **no resampling** vs. **`caret` upsampling (`sampling = "up"`)** vs. **SMOTE (`sampling = "smote"`)**, alongside **feature scaling** (`center + scale` vs. L2 normalization), to empirically show how enrichment improves Sensitivity & F1 under class imbalance (~1–2% bats).
3. **MLP Hyperparameter Tuning (`caret::train`)**:
   - Use `trainControl(method = "repeatedcv", number = 5, repeats = 5, classProbs = TRUE, summaryFunction = prSummary / twoClassSummary, savePredictions = "final")`.
   - Tune hidden layer size (`size`, e.g., `c(5, 10, 20, 30)`) and weight decay (`decay` with `method = "mlpWeightDecay"`) to avoid overfitting (`RP` Slide 39).
4. **Performance Evaluation**:
   - Compute `caret::confusionMatrix(pred, truth, positive = "Morcego", mode = "everything")` on both **5×5 CV** and the **unseen 20% holdout test set**.
   - Report all required metrics:
     - **Sensibilidade (Sensitivity / Recall)**: `VP / (VP + FN)`
     - **Precisão (Precision / PPV)**: `VP / (VP + FP)`
     - **Acurácia (Accuracy)**: `(VP + VN) / N` (contextualized against the ~98–99% majority baseline)
     - Plus **Especificidade**, **F1-score**, **ROC-AUC**, Confusion Matrix, and a quick list of any FP/FN organisms by name.

### Step 4 — Deliverables & Report Support (`R/04_export_results.R`)
*Covers criteria **(c), (h), (i)**.*

- **Data Files**:
  - `outputs/classificacao_final.csv`: `indice` (1..8426), `nome_cientifico`, `classe` (`1` = Morcego, `0` = Outro), `prob_mlp`.
  - `outputs/indices_morcegos.txt`: Ordered 1-based list of positive indices and bat species names.
- **4 Clean `ggplot2` Figures (Portuguese labels)**:
  1. `fig1_pca_morcegos.png`: PC1 vs. PC2 scatter showing all 8,426 organisms with discovered bats highlighted.
  2. `fig2_curva_prospeccao.png`: Cumulative bats discovered per round / oracle queries vs. random search.
  3. `fig3_enriquecimento_mlp.png`: MLP performance across enrichment strategies (Raw vs. Upsampling vs. SMOTE) and hidden-layer sizes.
  4. `fig4_desempenho_mlp.png`: Confusion Matrix + ROC / Precision-Recall curve of the final MLP.
- **Report & Presentation**: Once the scripts finish running, draft the 6-section report (`h`) and a concise 10-minute defense outline (`i`).

---

## 5. Quick Check Before We Code

1. **Clean up old Python files?** Should I remove the earlier Python prototype (`src/`, `scripts/`, `pyproject.toml`, `.venv/`, `state/`, `outputs/`) before creating the clean `R/` project, or keep them aside?
2. **`caret` MLP method**: Happy with `method = "mlpWeightDecay"` (from `RSNNS`, tunes both hidden neurons `size` and regularization `decay` to prevent overfitting), or do you specifically want plain `method = "mlp"` (`size` only)?
3. **Resampling inside `caret`**: Compare **Raw vs. `up` (built-in) vs. `smote` (`themis`)**?

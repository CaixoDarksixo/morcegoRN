# Roteiro da Apresentação (10 Minutos) — Equipe de 4 Integrantes

**Trabalho:** Reconhecimento de Padrões – É morcego? (DS803 – UFPR)  
**Equipe:** João Gabriel Fanti • João Victor Leal Gonçalves • João Pedro Nossol • Lucas Santana  
**Slides:** [Apresentacao_Morcegos.pptx](./Apresentacao_Morcegos.pptx) / [Apresentacao_Morcegos.pdf](./Apresentacao_Morcegos.pdf) (14 slides, ~2 min 30 s por integrante)

---

## Parte 1 — João Gabriel Fanti (Slides 1 a 4 | 0:00 – 2:30)

### Slide 1 — Capa (0:00 – 0:20)
> "Boa noite, professor e colegas. Nós somos João Gabriel, João Victor, João Pedro e Lucas, e vamos apresentar o trabalho *Reconhecimento de Padrões – É morcego?*, desenvolvido em R com `caret` e redes MLP."

### Slide 2 — O Problema (0:20 – 1:00)
> "O desafio é identificar todos os morcegos — ordem *Chiroptera* — entre 8.426 espécies sem nenhum rótulo inicial. São três dificuldades principais: rotular tudo na mão seria inviável; há um desbalanceamento extremo, porque morcegos são menos de 1% da base — um modelo que chutasse sempre 'Outro' já teria 99% de acurácia com 0% de sensibilidade; e biologicamente os morcegos ficam muito próximos de outros mamíferos da mesma superordem."

### Slide 3 — Os Dados SWeeP-PCA (1:00 – 1:45)
> "Os padrões vêm do método SWeeP que vimos em aula — proteomas mitocondriais projetados de 160 mil dimensões para 600 e reduzidos por PCA para as 50 componentes de `wpc50.dat`. A base não tem valores faltantes, mas a norma dos vetores varia bastante, de 0,15 a 9,47, o que nos levou a comparar Z-score e normalização L2. No gráfico PC1 por PC2 já dá para ver como os morcegos formam uma região bem concentrada. Implementamos tudo em R 4.5 com `caret`, `RSNNS`, `smotefamily`, `pROC` e `ggplot2`."

### Slide 4 — O Pipeline de Prospecção Ativa (1:45 – 2:30)
> "Para resolver a falta de rótulos, montamos um ciclo de 4 passos: primeiro, partimos de 49 sementes conhecidas da literatura; segundo, treinamos um MLP no `caret` para pontuar os organismos ainda não rotulados; terceiro, verificamos no console do RStudio um lote de apenas 20 candidatos por rodada — 15 de maior probabilidade e 5 de fronteira perto de 0,5; e quarto, encerramos após duas rodadas consecutivas sem novos morcegos mais uma varredura independente por distância cosseno. Passo para o João Victor mostrar a prospecção na prática."

---

## Parte 2 — João Victor Leal Gonçalves (Slides 5 a 7 | 2:30 – 5:00)

### Slide 5 — Sementes Balanceadas e 1ª Rodada no RStudio (2:30 – 3:15)
> "Na Rodada 0, escolhemos 10 morcegos cobrindo *ambas* as subordens — *Yinpterochiroptera* e *Yangochiroptera* — para o modelo não ficar enviesado para apenas um ramo evolutivo. Também colocamos 39 não-morcegos diversos, incluindo vários mamíferos próximos, para que o MLP aprendesse desde o início a separar morcegos de outros mamíferos. Aqui no print do RStudio já vemos a primeira proposta da rede: os 15 candidatos de alta probabilidade já são todos do gênero *Myotis*, acima de 0,91."

### Slide 6 — Rodadas 1 e 2 na Prática (3:15 – 4:10)
> "Na Rodada 1 acertamos 15 de 15 nos candidatos de alta probabilidade, subindo de 10 para 25 morcegos logo de cara. Na Rodada 2, o MLP repetiu 15 de 15, expandindo para outros gêneros como *Murina* e *Chalinolobus*. No print da direita dá para ver como fizemos a verificação taxonômica real lado a lado no navegador — por exemplo conferindo *Orthotermes depressifrons*, um cupim africano trazido pela fronteira."

### Slide 7 — Rodadas 5 e 6: Hard Negatives e o 79º Morcego (4:10 – 5:00)
> "Nas rodadas intermediárias o modelo foi capturando famílias cada vez mais diversas — como *Mystacina*, *Vampyrum* e *Pteronotus* — enquanto os 5 exemplos de fronteira traziam *hard negatives* valiosos da ordem *Eulipotyphla*, como toupeiras e gimnuros (*Hylomys* e *Scapanulus*). Na Rodada 6 surgiu o 79º e último morcego, *Anoura caudifer*, com probabilidade 0,73, enquanto os outros 19 candidatos já eram não-morcegos. Agora o João Pedro mostra a convergência e a modelagem do classificador."

---

## Parte 3 — João Pedro Nossol (Slides 8 a 10 | 5:00 – 7:30)

### Slide 8 — Convergência e Varredura de Sanidade (5:00 – 5:50)
> "Nas Rodadas 7 e 8 não apareceu nenhum morcego novo — o MLP já testava apenas musaranhos, toupeiras e mustelídeos com probabilidades abaixo de 0,34, como o *Neomys fodiens* aqui no print. Atingido o critério de duas rodadas zeradas, fizemos uma varredura de sanidade independente do MLP: pegamos os 20 organismos não rotulados com menor distância cosseno aos 79 morcegos confirmados — vieram só toupeiras, rinocerontes, camelos e focas, confirmando zero morcegos restantes."

### Slide 9 — Eficiência da Prospecção (5:50 – 6:35)
> "Essa curva resume a eficiência do aprendizado ativo em relação a uma busca aleatória: encontramos todos os 79 morcegos — abrangendo 32 gêneros diferentes — verificando apenas 229 dos 8.426 organismos, ou seja, só 2,7% da base. Com isso congelamos a base supervisionada com 79 positivos e 8.347 negativos."

### Slide 10 — Classificador MLP e Enriquecimento (6:35 – 7:30)
> "Com a base pronta, fizemos o benchmark do MLP via `caret::mlpWeightDecay` em uma divisão estratificada 80/20. Como os morcegos são só 0,94% da base, comparamos dentro das dobras de validação cruzada o treino sem balanceamento, com *upsampling* e com **SMOTE**, tanto em Z-score quanto em L2. O **Z-score com SMOTE** venceu com F1 de 0,9871, zerando falsos negativos e mantendo 97,5% de precisão. No ajuste fino em validação cruzada 5×5, o ponto ótimo foi `size = 10` neurônios ocultos e `decay = 0`, chegando a F1 = 0,9911 — enquanto `decay = 0,001` já derrubou a performance por subajuste no RSNNS. Passo para o Lucas fechar com os testes finais."

---

## Parte 4 — Lucas Santana (Slides 11 a 14 | 7:30 – 10:00)

### Slide 11 — Avaliação Estatística do MLP Final (7:30 – 8:25)
> "Na avaliação final em validação cruzada 5×5 (25 dobras), o MLP atingiu **100% de sensibilidade**, **98,29% de precisão**, **99,98% de acurácia**, **99,98% de especificidade** e **F1-score de 0,9911**, com ROC-AUC de 1,000. No conjunto de teste *holdout* inédito (20%, 1.684 organismos), acertou todos os 15 morcegos com apenas 1 falso positivo. E nas predições *out-of-fold* sobre toda a base de 8.426 organismos, obteve 99,99% de acurácia, 100% de sensibilidade e F1 de 0,9937 — com diferença mínima em relação ao treino, confirmando ausência de *overfitting*."

### Slide 12 — Análise Biológica do Único Erro (8:25 – 9:15)
> "Um resultado muito interessante aparece quando olhamos os erros *out-of-fold* nos 8.426 organismos: tivemos **zero falsos negativos** — todos os 79 morcegos foram reconhecidos — e apenas **1 único falso positivo** em 8.347 não-morcegos: o índice 3597, *Hylomys suillus*, com probabilidade limítrofe de 0,545. Biologicamente, o *Hylomys suillus* é um gimnuro da ordem *Eulipotyphla*, justamente o grupo-irmão evolutivo dos morcegos dentro de *Laurasiatheria*. Isso mostra que o único erro acontece exatamente na fronteira biológica esperada."

### Slide 13 — Síntese (9:15 – 9:45)
> "Para sintetizar: nossa prospecção iterativa reduziu em **97,3%** o esforço manual de rotulagem, localizou 79 morcegos de 32 gêneros e o classificador MLP com SMOTE entregou 100% de sensibilidade, 98,3% de precisão e F1 de 0,991."

### Slide 14 — Encerramento (9:45 – 10:00)
> "Todos os entregáveis — classificação completa dos 8.426 organismos, lista de índices base 1, scripts em R e relatório — estão disponíveis. Muito obrigado pela atenção, ficamos à disposição para perguntas!"

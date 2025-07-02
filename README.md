# Using Computer Vision to Measure Design Similarity: An Application to Design Rights

This repository contains the data and code pack for the paper _"Using Computer Vision to Measure Design Similarity: An Application to Design Rights"_ submitted to *Research Policy*.

---

## 📁 Folder Contents


### 🧮 CODES
1. `SSIM.py`: Python code to measure the structural similarity index (SSIM), based on Wang et al., 2004.
2. `Code.do`: Stata code to replicate the transformation from design pairs to design space similarity density (DSSD).

### 🖼️ IMAGE DATA
- `Preprocessed/`: A sample of cleaned images of design rights included in USPC Subclass D14-1380AC (Mobile Phones).

### 📊 STRUCTURED DATA 

1. `DesignMetaInfo.dta`: Design-level application data with USPC class and subclass.
2. `DesignPairs*.dta`: Design pair similarity chunks (partitioned from 1 to 35) based on SSIM (see `DesignPairs/`).
3. `NearestNeighbor.dta`: Design-level average nearest neighbor measures (1-nn, 3-nn, 5-nn).
4. `DSSD.dta`: Subclass-level data on Design Space Similarity Density.
5. `SubclassOutcomeControls.dta`: Subclass-level litigation outcomes and control variables.

---

## 📘 Data Dictionary

### A. Design Rights Meta Information — `DesignMetaInfo.dta`
**Source**: [patentsview.org](https://patentsview.org)  
**Note**: `design2 = design1` by default; the fields aid in merging to similarity data.

| Variable        | Description |
|----------------|-------------|
| `uspc_class`   | Primary classification under USPC (broad category) |
| `uspc_subclass`| Secondary classification under USPC (specific category) |
| `design1`      | Unique ID for focal design |
| `design2`      | Unique ID for compared design |
| `date2`        | Application date of design right |

---

### B. Design Pair Similarity Data (chunked into 35 partitions) — `DesignPair*.dta`
**Source**: [patentsview.org](https://patentsview.org), `SSIM.py`

| Variable  | Description |
|-----------|-------------|
| `design1` | Focal design ID |
| `design2` | Compared design ID |
| `ssim`    | SSIM-based visual similarity score |

---

### C. Nearest Neighbor — `NearestNeighbor.dta`
**Source**: [patentsview.org](https://patentsview.org), `DesignPair*.dta`

| Variable  | Description |
|-----------|-------------|
| `design`  | Focal design ID |
| `nn_1`    | SSIM with closest neighbor |
| `nn_3`    | Average SSIM with top 3 neighbors |
| `nn_5`    | Average SSIM with top 5 neighbors |

---

### D. DSSD — `DSSD.dta`
**Source**: [patentsview.org](https://patentsview.org), `NearestNeighbor.dta`

| Variable     | Description |
|--------------|-------------|
| `uspc_class` | Primary USPC classification |
| `uspc_subclass` | Secondary USPC classification |
| `year`       | Calendar year |
| `dssd_5`     | Avg. SSIM for 5-NN |
| `dssd_3`     | Avg. SSIM for 3-NN |
| `dssd_1`     | SSIM for 1-NN |

---

### E. Subclass Litigation Outcome and Control — `SubclassOutcomeControls.dta`

| Variable                       | Description |
|--------------------------------|-------------|
| `uspc_class`                   | Primary USPC classification |
| `uspc_subclass`               | Secondary USPC classification |
| `year`                         | Calendar year |
| `subclass_litigation_count`    | Total designs litigated per subclass-year |
| `subclass_no_unq_designs`      | Unique design rights per subclass-year |
| `subclass_ave_firm_no_unq_des`| Avg. designs per firm in subclass-year |
| `subclass_var_firm_no_unq_des`| Variance in firm design filings |
| `subclass_no_unq_atty`         | Unique attorneys in subclass-year |
| `subclass`                     | Unique subclass identifier |



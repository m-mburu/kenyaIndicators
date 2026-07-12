# Kenya DHS National Indicators Dashboard Plan

## Source Read

Dataset: [Kenya - National Demographic and Health Data](https://data.humdata.org/dataset/dhs-data-for-kenya) from HDX, sourced from [The DHS Program API](https://api.dhsprogram.com/).

Policy framing sources:

- [United Nations Sustainable Development Goals](https://sdgs.un.org/goals): 17 goals, 169 targets, and annual SDG progress reporting based on the global indicator framework.
- [Kenya Vision 2030](https://vision2030.go.ke/about-vision-2030/): Kenya's long-term blueprint for a globally competitive, prosperous country with high quality of life by 2030, organized around economic, social, political, and enabling pillars.

Key metadata observed from the HDX API:

- Country: Kenya
- Geography level: national
- Dataset period: 1993-2022 in HDX metadata, with some indicator series extending to 1989 in the CSV resources
- Methodology: sample survey
- Resource format: CSV
- Number of HDX resources: 46
- Parsed coverage: 1,570 resource-indicator entries across all resources
- Common columns: `ISO3`, `DataId`, `Indicator`, `Value`, `Precision`, `DHS_CountryCode`, `CountryName`, `SurveyYear`, `SurveyId`, `IndicatorId`, `IndicatorOrder`, `IndicatorType`, `CharacteristicId`, `CharacteristicOrder`, `CharacteristicCategory`, `CharacteristicLabel`, `ByVariableId`, `ByVariableLabel`, `IsTotal`, `IsPreferred`, `SDRID`, `RegionId`, `SurveyYearLabel`, `SurveyType`, `DenominatorWeighted`, `DenominatorUnweighted`, `CILow`, `CIHigh`, `LevelRank`

The dashboard should preserve the DHS indicator structure rather than flattening everything into one unlabeled metric list. The right mental model is: domain resource -> indicator -> survey year -> characteristic/breakdown -> value, denominator, uncertainty.

## Dashboard Goal

Build a comprehensive national dashboard that lets users understand Kenya's DHS indicator trends as evidence for SDG progress and Kenya Vision 2030. The dashboard should answer: **Where is Kenya, based on DHS-relevant indicators, against the Sustainable Development Goals and Vision 2030 social-development ambitions?**

The dashboard should still let users compare domains, inspect detailed indicator metadata, and export analysis-ready tables. But the main organizing frame should move from "all indicators" to "policy status": SDG goal -> Vision 2030 pillar/theme -> DHS evidence -> progress status -> caveats.

## Hypothesis-Driven Framing

The dashboard should not be organized as a gallery of figures. It should be organized around testable public-health and development hypotheses, similar to how the Vis & Society housing theme frames visualization work around a civic problem, competing explanations, affected groups, relevant policy debates, background readings, and datasets.

The core framing question should be:

**Which linked changes in fertility, family planning, maternal care, child health, nutrition, education, HIV, malaria, WASH, household conditions, and gender autonomy best explain Kenya's long-run DHS progress, and where do persistent risks remain?**

This framing shifts the dashboard from "show every indicator" to "use every indicator as evidence." The full indicator catalogue remains available, but the main user journey should begin with hypotheses that can be supported, challenged, or refined using the DHS data.

### Anchor Hypotheses

| Hypothesis | Evidence indicators | Dashboard treatment | What would strengthen or weaken the hypothesis |
|---|---|---|---|
| H1: Fertility decline is connected to increased modern contraception and reduced unmet need. | Total fertility rate, wanted fertility rate, modern method use, any contraception, unmet need, demand satisfied, ideal number of children | Fertility and family planning story page with paired trends and indexed comparison | Strengthened if fertility falls as modern method use and demand satisfied rise; weakened if trends diverge or time windows do not overlap |
| H2: Child survival improved alongside better immunization, diarrhea treatment, nutrition, WASH, and malaria prevention. | Neonatal, infant, child, under-five mortality, full vaccination, ORS/RHF diarrhea treatment, stunting, wasting, improved water, sanitation, ITN use | Child survival story page with outcome trends on top and contributing-factor panels below | Strengthened if mortality declines while protective indicators improve; weakened where protective indicators are flat, sparse, or unavailable |
| H3: Maternal and newborn outcomes are linked to service access and facility delivery. | Health facility delivery, skilled provider, antenatal care where available, access-to-care barriers, maternal mortality, pregnancy-related mortality | Maternal health pathway with care cascade and barrier ranking | Strengthened if care use increases and mortality decreases; weakened by sparse mortality series and wide uncertainty |
| H4: Education, literacy, media access, and digital access shape reproductive health, HIV knowledge, and autonomy. | Women's and men's literacy, secondary or higher education, media access, internet use, mobile phone ownership, HIV knowledge, final say in own health care | Education and agency story page using cross-domain small multiples | Strengthened by aligned improvements in knowledge/autonomy indicators; weakened because national aggregates cannot prove individual-level causality |
| H5: HIV risk has shifted from awareness gaps to behavior, testing, stigma, and service uptake gaps. | HIV knowledge, attitudes, behavior, counseling/testing, prevalence, male circumcision, sexual intercourse indicators | HIV story page with knowledge-testing-behavior-prevalence sections | Strengthened if knowledge is high but testing, stigma, or behavior indicators lag |
| H6: Malaria protection depends on ownership-to-use conversion, not only availability of ITNs. | Household ITN ownership, children under 5 sleeping under ITN, pregnant women using ITN, parasitemia, PMI/RBM indicators | Malaria prevention cascade | Strengthened if ownership rises faster than actual use, revealing a use gap |
| H7: WASH and household living conditions are cross-cutting risk factors for COVID prevention, child health, and nutrition. | Improved water, water on premises, sanitation, open defecation, handwashing, crowding, household members, electricity | WASH and household context story page | Strengthened if WASH and crowding indicators show persistent gaps despite progress elsewhere |
| H8: Gender autonomy and violence indicators should be treated as central outcomes, not side notes. | Final say in own health care, partner violence, FGC, selected gender indicators | Gender and safety page with careful caveats and table-first design | Strengthened if autonomy and violence trends diverge from general health progress |

### Hypothesis Page Template

Each story page should follow the same evidence structure:

1. Claim: one clear sentence stating the hypothesis.
2. Why it matters: short policy or public-health rationale.
3. Evidence map: list of DHS indicators used as outcomes, drivers, and context.
4. Primary view: one main chart that tests the hypothesis.
5. Supporting views: two to four charts/tables that explain mechanisms or exceptions.
6. Caveats: survey years, missing indicators, confidence intervals, denominator warnings, and national-only limitations.
7. What to inspect next: links to related indicators and the full data table.

### Dashboard Design Implication

The Overview page should open with "What story does the DHS evidence tell?" rather than "Latest indicators." A strong first screen would show:

- one national progress timeline made from pinned outcome indicators
- one "drivers of change" panel for family planning, education, WASH, immunization, malaria, and facility delivery
- one "persistent risks" panel for indicators that remain high, stagnant, sparse, or uncertain
- one "evidence confidence" panel showing which claims are well-supported by repeated survey years and which rely on sparse data

The All Indicators page should still exist, but it should be the evidence library behind the hypotheses, not the conceptual center of the dashboard.

## SDG and Vision 2030 Framing

The dashboard should use the SDGs and Kenya Vision 2030 as the main navigation and interpretation layer.

The SDG source frames the 2030 Agenda as 17 Sustainable Development Goals with 169 targets, adopted by all UN Member States in 2015 as a shared blueprint for people, planet, prosperity, peace, and partnership. The UN SDG site also emphasizes annual progress reporting based on the global indicator framework and national statistical systems.

Kenya Vision 2030 is Kenya's long-term national development blueprint. Its stated ambition is to make Kenya a globally competitive and prosperous country with a high quality of life by 2030, transforming the country into a newly industrialising, middle-income country in a clean and secure environment. It is organized around the Economic Pillar, Social Pillar, Political Pillar, and enabling foundations such as infrastructure, science/technology/innovation, human resources development, security, public-sector reforms, land reforms, and macroeconomic stability.

For this DHS dashboard, the best product framing is:

**Kenya SDG and Vision 2030 Social Progress Dashboard: DHS evidence on health, nutrition, education, gender, WASH, household living conditions, and population change.**

This means the dashboard should explicitly distinguish between:

- **Direct DHS evidence:** indicators that closely match an SDG target or Vision 2030 social objective.
- **Proxy DHS evidence:** indicators that do not fully measure a target but illuminate progress or risk.
- **Evidence gaps:** SDG or Vision 2030 questions DHS cannot answer alone and should link to other datasets.

### Status Logic

The dashboard should assign a transparent status to each SDG/Vision theme, based only on indicators available in the preprocessed DHS data unless external official targets are added later.

Recommended status labels:

| Status | Meaning | Rule of thumb |
|---|---|---|
| On track / strong progress | Latest value and trend point in the desired direction | repeated survey years, latest estimate available, improvement from baseline |
| Mixed progress | Some indicators improve while others stagnate or worsen | domain has conflicting evidence |
| Stalled | Little or no meaningful change from baseline | repeated years but small change |
| Regression | Latest value is worse than baseline in the expected direction | repeated years and negative movement |
| Insufficient DHS evidence | Too few survey years or DHS does not measure the target well | sparse series, no denominator/CI, or not a DHS topic |

The status method should never hide uncertainty. Each status card should show the number of indicators used, latest survey year, baseline year, confidence interval availability, denominator availability, and a caveat when the evidence is only a proxy.

### DHS-Relevant SDG Mapping

| SDG | DHS relevance | Example DHS evidence | Dashboard interpretation |
|---|---|---|---|
| SDG 1: No Poverty | Proxy only | household electricity, assets, sanitation, water, crowding, health insurance | DHS can show living-condition deprivation but not income poverty directly |
| SDG 2: Zero Hunger | Strong partial evidence | stunting, wasting, underweight, anemia, IYCF, micronutrients, iodized salt | nutrition status and feeding practices are core DHS evidence |
| SDG 3: Good Health and Well-being | Strong evidence | fertility, maternal care, child mortality, immunization, diarrhea treatment, HIV, malaria, tobacco, mortality | this should be the strongest SDG page in the dashboard |
| SDG 4: Quality Education | Partial evidence | literacy, women/men with secondary or higher education, media access | DHS gives education attainment/literacy, not school quality |
| SDG 5: Gender Equality | Strong partial evidence | women's decision-making, partner violence, FGC, gender indicators, age at marriage, reproductive autonomy | central story page; sensitive indicators need careful caveats |
| SDG 6: Clean Water and Sanitation | Strong evidence | improved water source, basic water service, sanitation, open defecation, handwashing | strong DHS household evidence, but not full water-system governance |
| SDG 7: Affordable and Clean Energy | Partial proxy | household/population electricity access, cooking fuel if available | DHS supports household access, not affordability or renewable mix |
| SDG 8: Decent Work and Economic Growth | Limited DHS evidence | indirect: education, internet/mobile access, household conditions | needs labor, GDP, employment, and productivity data outside DHS |
| SDG 9: Industry, Innovation and Infrastructure | Limited proxy | electricity, internet use, mobile phone ownership | DHS can proxy household connectivity, not industrialization |
| SDG 10: Reduced Inequalities | Partial if disaggregations are available | sex, wealth, education, age, residence breakdowns where present | national dataset limits inequality analysis; subnational DHS would improve this |
| SDG 11: Sustainable Cities and Communities | Partial proxy | water, sanitation, crowding, household services | national DHS lacks full urban planning, housing, transport, and city data |
| SDG 12: Responsible Consumption and Production | Limited DHS evidence | household assets and waste/sanitation proxies only | likely an evidence gap |
| SDG 13: Climate Action | Limited DHS evidence | malaria, water, nutrition vulnerability proxies | needs climate, disaster, emissions, and adaptation datasets |
| SDG 14: Life Below Water | Not covered by DHS | none | evidence gap |
| SDG 15: Life on Land | Not covered by DHS | none | evidence gap |
| SDG 16: Peace, Justice and Strong Institutions | Limited partial evidence | birth registration, violence indicators | DHS covers some civil registration/safety outcomes, not institutions broadly |
| SDG 17: Partnerships for the Goals | Not covered by DHS | none | evidence gap |

### Vision 2030 Mapping

| Vision 2030 component | DHS relevance | Example DHS evidence | Dashboard treatment |
|---|---|---|---|
| Social Pillar: investing in people | Strong evidence | health, education, nutrition, WASH, gender, household welfare | primary Vision 2030 page |
| Economic Pillar: moving the economy up the value chain | Proxy only | education, electricity, digital access, household conditions | mark as partial; use companion economic data later |
| Political Pillar: issue-based, people-centered, accountable system | Limited evidence | birth registration, violence/safety-related indicators, service access barriers | mostly evidence gaps; avoid overclaiming |
| Enablers and foundations: infrastructure | Partial evidence | electricity, water source, sanitation, mobile ownership, internet use | household-level service access dashboard |
| Enablers and foundations: human resources development | Partial evidence | literacy, education attainment, health/nutrition outcomes | link education and health capability indicators |
| Enablers and foundations: security/public-sector reforms/STI/land/macro stability | Limited or no DHS evidence | selected household/digital proxies only | companion datasets needed |

### SDG/Vision Dashboard Pages

The dashboard should add these pages or reframe current pages around them:

| Page | Main question | Primary visuals |
|---|---|---|
| SDG Status Overview | Which DHS-relevant SDGs show strong, mixed, stalled, or insufficient progress? | 17 SDG cards, status chips, evidence count, latest year, mini trend |
| SDG 2 Nutrition | Is Kenya improving nutrition and food-security-related outcomes? | stunting/wasting/underweight trends, anemia table, IYCF scorecard |
| SDG 3 Health | Is Kenya improving health and well-being across the life course? | maternal-child-health pathway, mortality trends, immunization, HIV, malaria |
| SDG 4 Education | What does DHS say about literacy and education attainment? | sex-disaggregated literacy/education trends, latest-value bars |
| SDG 5 Gender | What is the status of gender equality, autonomy, safety, and harmful practices? | autonomy, FGC, partner violence, age-at-marriage indicators with caveats |
| SDG 6 WASH | Is access to water, sanitation, and handwashing improving? | WASH service ladder, open defecation, handwashing, improved source trends |
| SDG 7/9 Connectivity and Infrastructure | What household-level infrastructure progress is visible? | electricity, mobile ownership, internet use, household assets |
| Vision 2030 Social Pillar | Is Kenya making progress on high quality of life and equitable social development? | combined scorecard across health, education, WASH, nutrition, gender |
| Evidence Gaps | Which SDG/Vision questions cannot DHS answer? | gap matrix and recommended companion datasets |

### Data Model Additions

Add these precomputed fields during `data-raw/my_dataset.R` preprocessing, not in Shiny:

- `sdg_goal_id`
- `sdg_goal_name`
- `sdg_target_proxy`
- `sdg_evidence_type`: direct, proxy, gap
- `vision2030_pillar`
- `vision2030_theme`
- `desired_direction`: increase, decrease, context_only
- `baseline_value`
- `latest_value`
- `change_from_baseline`
- `status_label`
- `status_reason`
- `evidence_strength`: strong, partial, sparse, gap

This should be implemented as a hand-curated mapping table first. Do not infer SDG mappings only from text search, because indicator names can be misleading. The app should allow users to inspect the mapping and see why each indicator was assigned to an SDG or Vision 2030 theme.

## Primary User Questions

- What is Kenya's DHS-relevant status for each SDG, especially SDG 2, 3, 4, 5, 6, 7, 10, 11, and 16?
- Where does DHS evidence suggest strong progress, mixed progress, stalled progress, regression, or insufficient evidence?
- Which Vision 2030 social-pillar ambitions are supported by DHS evidence, and which require companion datasets?
- Which indicators have the latest 2022 values, and which SDG/Vision themes rely on older estimates?
- Which indicators improved, worsened, or remained flat between the earliest and latest available survey year?
- Which estimates are based on small denominators, sparse years, or wide confidence intervals?
- Where do SDG and Vision 2030 claims rely on direct DHS evidence versus proxy evidence?
- Which SDG/Vision questions cannot be answered from DHS alone?

## Recommended Dashboard Structure

### 0. SDG and Vision 2030 Status Overview

Purpose: make the first screen answer the user's main policy question: **Where is Kenya against the SDGs and Vision 2030, based on DHS-relevant evidence?**

Components:

- SDG status grid with all 17 SDGs:
  - status label: strong progress, mixed progress, stalled, regression, insufficient DHS evidence
  - evidence type: direct, proxy, gap
  - count of mapped DHS indicators
  - latest available survey year
  - confidence/denominator availability
  - link to detailed SDG page or evidence-gap note
- Vision 2030 pillar strip:
  - Social Pillar status card
  - Economic Pillar proxy evidence card
  - Political Pillar limited-evidence card
  - Enablers/foundations card
- Evidence confidence summary:
  - indicators with repeated survey years
  - indicators with 2022 latest estimate
  - indicators with confidence intervals
  - SDG/Vision themes requiring external datasets
- Main visual:
  - SDG-by-status matrix, with goal cards colored by status rather than a decorative rainbow
  - clicking an SDG filters the rest of the dashboard
- Narrative text:
  - one sentence for each high-evidence SDG: "DHS evidence suggests..."
  - one sentence for evidence gaps: "DHS cannot answer..."

### 1. DHS Evidence Overview

Purpose: give a fast, high-confidence summary of the DHS indicators that drive SDG and Vision 2030 status calls.

Components:

- KPI strip using DHS Quickstats:
  - Total fertility rate
  - Modern contraceptive use among married women
  - Unmet need for family planning
  - Under-five mortality rate
  - Infant mortality rate
  - Children stunted
  - Fully vaccinated with 8 basic antigens
  - Health facility delivery
  - HIV testing among women and men
  - Women with secondary or higher education
  - Households with electricity
  - Improved water source and improved sanitation
- Each KPI card should show:
  - latest value
  - latest survey year
  - change from earliest comparable year
  - mini trend sparkline
  - denominator and confidence interval availability icon
- "Latest survey snapshot" table:
  - indicator
  - value
  - survey year
  - characteristic
  - denominator weighted/unweighted
  - confidence interval
- Trend panel:
  - multi-line chart for 6-10 pinned indicators
  - year on x-axis, value on y-axis
  - toggle between absolute value and indexed change from first available year
- Short narrative text:
  - autogenerated "headline findings" from latest values and largest changes
  - examples: "Fertility declined", "modern method use increased", "stunting declined", "electricity access increased"

### 2. Domain Explorer

Purpose: expose all 46 indicator resources without overwhelming users.

Components:

- Left-side domain navigation grouped into:
  - Summary and external frameworks: Quickstats, Mobile, SDGs, MDGs, PMI/RBM, MICS, FP2020
  - Reproductive, maternal, fertility, and family planning
  - Child health and mortality
  - Nutrition and anthropometry
  - HIV and sexual health
  - Malaria
  - Education, literacy, media, and digital access
  - WASH and household living conditions
  - Gender, violence, autonomy, and social indicators
  - COVID-19 prevention and contextual factors
- Domain cards showing:
  - resource name
  - indicator count
  - row count
  - year coverage
  - most recent survey year
  - suggested primary chart type
- Search box across `Indicator`, `IndicatorId`, `CharacteristicLabel`, and `ByVariableLabel`.
- Filter chips:
  - survey year
  - survey type
  - characteristic category
  - total/preferred estimate
  - indicator type
  - denominator availability
  - confidence interval availability

### 3. Indicator Detail Page

Purpose: make every indicator inspectable and reusable.

Layout:

- Header:
  - indicator name
  - `IndicatorId`
  - resource/domain
  - latest value and survey year
  - available year range
- Primary trend chart:
  - line chart with points for survey years
  - confidence interval ribbon when `CILow` and `CIHigh` exist
  - visual marker for `IsPreferred`
- Breakdown chart:
  - grouped bars or small multiples for `ByVariableLabel` or `CharacteristicLabel`
  - use when the indicator has categories such as sex, age group, number of living children, marital status, or preceding-year window
- Metadata panel:
  - `SurveyId`, `SurveyType`, `SurveyYearLabel`
  - `CharacteristicCategory`, `CharacteristicLabel`
  - denominator weighted/unweighted
  - precision
  - `IsTotal`, `IsPreferred`
- Data table:
  - every row used in the chart
  - sortable columns
  - CSV export
- Notes:
  - warn when only one or two years are available
  - warn when latest value is not 2022
  - warn when values are not comparable because breakdown labels differ

### 4. Cross-Domain Story Pages

Purpose: turn the large indicator catalogue into meaningful policy narratives.

Recommended story pages:

- Fertility and family planning:
  - total fertility rate, wanted fertility, ideal number of children
  - contraceptive prevalence, modern method use, unmet need, demand satisfied
  - men's fertility and family planning indicators
  - charts: paired trend lines, stacked method mix bars, indicator correlation matrix
- Maternal and newborn health:
  - antenatal care, place of delivery, skilled provider, health facility delivery
  - maternal mortality and pregnancy-related mortality
  - access to health care barriers
  - charts: trend lines, barrier ranking bars, uncertainty intervals
- Child survival and child health:
  - neonatal, infant, child, and under-five mortality
  - immunization
  - diarrhea treatment
  - ARI symptoms and treatment
  - birth registration
  - charts: mortality trend lines, immunization coverage heatmap, treatment cascade
- Nutrition:
  - stunting, wasting, underweight
  - anemia
  - IYCF
  - micronutrients
  - iodized salt
  - charts: nutrition scorecard, line trends, age/breakdown small multiples
- HIV:
  - HIV knowledge, attitudes, behavior, counseling/testing, prevalence
  - male circumcision
  - sexual intercourse indicators
  - charts: sex-disaggregated trend lines, testing cascade, attitude/knowledge bars
- Malaria:
  - ITN ownership/use, child ITN use, pregnant women ITN use
  - malaria parasitemia
  - PMI/RBM and selected malaria indicators
  - charts: prevention cascade, trend lines, child/pregnancy comparison bars
- Education, literacy, and digital access:
  - literacy, secondary or higher education, media access
  - internet use, phone ownership, household mobile telephone
  - charts: sex-disaggregated trend lines, latest-value bars
- WASH and household conditions:
  - water source, sanitation, handwashing, toilet facilities
  - electricity, household assets, crowding
  - charts: improved/unimproved stacked bars, service ladder chart, trend lines
- Gender, autonomy, and violence:
  - decision-making in own health care
  - partner violence indicators
  - FGC where available
  - selected gender indicators
  - charts: sensitive-data scorecard, trend lines with clear caveats, compact table first
- COVID-19 prevention context:
  - water, sanitation, handwashing, crowding, older household members, household assets, smoking, internet/mobile access
  - charts: risk/context dashboard, latest-value grouped bars, time-series where available

### 5. Full Indicator Catalogue

Purpose: guarantee that no indicator is hidden.

Components:

- Searchable, paginated table with one row per unique resource-indicator combination.
- Columns:
  - resource
  - `IndicatorId`
  - indicator
  - years available
  - number of rows
  - breakdowns available
  - characteristics available
  - latest survey year
  - latest value
  - confidence interval availability
  - denominator availability
- Actions:
  - open indicator detail
  - pin to overview
  - compare with another indicator
  - export selected indicators

The catalogue should deduplicate for browsing by `IndicatorId`, but retain resource membership because several important indicators appear in Quickstats, Mobile, SDGs, MDGs, selected-indicator resources, and topic-specific resources.

## Visualization Rules

Use consistent chart templates rather than custom visuals for every indicator:

- Time series:
  - line with points for most national indicators
  - confidence interval ribbon when available
  - use only survey years, not interpolated annual values
- Latest-value comparison:
  - horizontal bar chart sorted by value
  - best for many indicators in one domain
- Breakdown comparison:
  - grouped bar chart for sex, age, residence, education, wealth, marital status, parity, or other `ByVariableLabel` groups
  - small multiples when more than 6 groups exist
- Composition:
  - stacked bars for method mix, water/sanitation ladder, smoking categories, vaccination components, and household assets
- Scorecards:
  - compact KPI cards for indicators that have clear directionality and repeated survey years
- Heatmaps:
  - indicator by survey year availability
  - domain by latest survey year
  - indicator by improvement/worsening status
- Tables:
  - always available below charts
  - preferred view for sparse indicators, sensitive violence indicators, or indicators with many categorical labels
- Narrative text:
  - one paragraph per domain summarizing latest level, direction since baseline, and data caveats
  - generate from rules, not manually hard-coded

## Data Handling Plan

### Raw Data

Ingest all 46 CSV resources from the HDX package. Keep each raw file intact and add a source manifest with:

- resource name
- HDX resource ID
- file name
- download URL
- last modified date
- row count
- indicator count

### Normalized Table

Create one long table called `dhs_national_indicators` with:

- source fields from the CSV
- normalized numeric `value`
- numeric `ci_low`, `ci_high`
- numeric denominators
- `resource_name`
- `resource_position`
- `resource_file`
- `domain_group`
- `indicator_slug`
- `latest_year_flag`
- `baseline_year_flag`
- `comparable_total_flag`

### Derived Tables

- `indicator_catalogue`: one row per resource-indicator pair
- `indicator_latest`: latest preferred/total row for each indicator and breakdown
- `indicator_trends`: earliest/latest/change calculations
- `domain_summary`: row count, indicator count, year coverage, latest year per domain
- `dashboard_pins`: curated overview indicators
- `quality_flags`: missing confidence intervals, missing denominators, sparse time series, non-2022 latest values, low denominator flags

### Comparability Rules

- Do not compare rows with different `CharacteristicLabel` unless explicitly selected.
- Prefer `IsPreferred == 1` when multiple estimates exist for the same indicator/year.
- Prefer `IsTotal == 1` for high-level KPI cards.
- Preserve `ByVariableLabel` because some indicators use time windows such as "five years preceding the survey" versus "ten years preceding the survey".
- Show confidence intervals and denominators whenever present.
- Never fill missing survey years by interpolation.

## Indicator Resource Inventory

| # | HDX resource | CSV file | Rows parsed | Unique indicators | Dashboard treatment |
|---:|---|---|---:|---:|---|
| 0 | DHS Quickstats Data for Kenya | `dhs-quickstats_national_ken.csv` | 191 | 28 | Overview KPIs and national headline trends |
| 1 | DHS Mobile Data for Kenya | `dhs-mobile_national_ken.csv` | 850 | 126 | Broad mobile-friendly indicator catalogue and core trends |
| 2 | SDGs Data for Kenya | `sdgs_national_ken.csv` | 214 | 38 | SDG-aligned scorecard and SDG indicator table |
| 3 | MDGs Data for Kenya | `mdgs_national_ken.csv` | 218 | 30 | Historical MDG benchmark view |
| 4 | PMI/RBM Data for Kenya | `pmi-rbm_national_ken.csv` | 89 | 16 | Malaria program scorecard |
| 5 | IYCF Data for Kenya | `iycf_national_ken.csv` | 66 | 14 | Infant and young child feeding page |
| 6 | MICS indicators Data for Kenya | `mics-indicators_national_ken.csv` | 587 | 90 | Child and household indicator catalogue |
| 7 | FP2020 Data for Kenya | `fp2020_national_ken.csv` | 230 | 47 | Family planning commitments scorecard |
| 8 | Access to Health Care Data for Kenya | `access-to-health-care_national_ken.csv` | 1,141 | 119 | Barriers and access explorer |
| 9 | Adult Mortality Data for Kenya | `adult-mortality_national_ken.csv` | 40 | 10 | Adult mortality trend panel |
| 10 | Anemia Data for Kenya | `anemia_national_ken.csv` | 18 | 9 | Anemia scorecard and sparse trend table |
| 11 | Anthropometry Data for Kenya | `anthropometry_national_ken.csv` | 144 | 24 | Nutrition trend and z-score status page |
| 12 | Birth Registration Data for Kenya | `birth-registration_national_ken.csv` | 15 | 5 | Birth registration mini-module |
| 13 | Child Mortality Rates Data for Kenya | `child-mortality-rates_national_ken.csv` | 130 | 15 | Mortality trends with survey window controls |
| 14 | Diarrhea Data for Kenya | `diarrhea_national_ken.csv` | 445 | 45 | Diarrhea prevalence and treatment cascade |
| 15 | Fertility Rates Data for Kenya | `fertility-rates_national_ken.csv` | 105 | 12 | Fertility trend dashboard |
| 16 | Health Insurance Data for Kenya | `health-insurance_national_ken.csv` | 32 | 16 | Health insurance coverage table and bars |
| 17 | HIV Attitudes Data for Kenya | `hiv-attitudes_national_ken.csv` | 86 | 28 | HIV stigma and attitudes explorer |
| 18 | HIV Behavior Data for Kenya | `hiv-behavior_national_ken.csv` | 387 | 101 | HIV behavior catalogue and trend panels |
| 19 | HIV Counseling and Testing Data for Kenya | `hiv-counseling-and-testing_national_ken.csv` | 151 | 51 | HIV testing cascade and sex-disaggregated trends |
| 20 | HIV Knowledge Data for Kenya | `hiv-knowledge_national_ken.csv` | 177 | 50 | Knowledge scorecard and misconception bars |
| 21 | HIV Prevalence Data for Kenya | `hiv-prevalence_national_ken.csv` | 62 | 31 | HIV prevalence trends with sex breakdown |
| 22 | Immunization Data for Kenya | `immunization_national_ken.csv` | 349 | 52 | Vaccination coverage heatmap and trend lines |
| 23 | Insecticide Treated Nets Data for Kenya | `insecticide-treated-nets_national_ken.csv` | 240 | 46 | ITN ownership/use and protection cascade |
| 24 | Iodized Salt Data for Kenya | `iodized-salt_national_ken.csv` | 21 | 7 | Iodized salt mini-module |
| 25 | Literacy Data for Kenya | `literacy_national_ken.csv` | 103 | 22 | Literacy by sex and education profile |
| 26 | Malaria Parasitemia Data for Kenya | `malaria-parasitemia_national_ken.csv` | 12 | 6 | Sparse malaria parasitemia table and trend |
| 27 | Male Circumcision Data for Kenya | `male-circumcision_national_ken.csv` | 24 | 9 | Male circumcision trend page |
| 28 | Maternal Mortality Data for Kenya | `maternal-mortality_national_ken.csv` | 40 | 10 | Maternal/pregnancy-related mortality with caveats |
| 29 | Men's Fertility and Family Planning Data for Kenya | `mens-fertility-and-family-planning_national_ken.csv` | 854 | 175 | Men's reproductive health explorer |
| 30 | Micronutrients Data for Kenya | `micronutrients_national_ken.csv` | 68 | 27 | Micronutrient coverage scorecard |
| 31 | Orphans Data for Kenya | `orphans_national_ken.csv` | 54 | 21 | Orphans and vulnerable children module |
| 32 | Symptoms of acute respiratory infection (ARI) Data for Kenya | `symptoms-of-acute-respiratory-infection-ari_national_ken.csv` | 72 | 7 | ARI symptom/treatment mini-module |
| 33 | Sexual Intercourse Data for Kenya | `sexual-intercourse_national_ken.csv` | 302 | 49 | Sexual behavior trend and age-at-first-sex panels |
| 34 | Social Marketing Data for Kenya | `social-marketing_national_ken.csv` | 12 | 6 | Social marketing sparse table |
| 35 | Tobacco Data for Kenya | `tobacco_national_ken.csv` | 75 | 20 | Tobacco use by sex and trend table |
| 36 | Toilet Facilities Data for Kenya | `toilet-facilities_national_ken.csv` | 218 | 34 | Sanitation ladder and toilet facility trends |
| 37 | Water Data for Kenya | `water_national_ken.csv` | 378 | 64 | Water source/service ladder dashboard |
| 38 | Select Malaria Indicators Data for Kenya | `select-malaria-indicators_national_ken.csv` | 77 | 15 | Curated malaria indicator overview |
| 39 | Select Gender Indicators Data for Kenya | `select-gender-indicators_national_ken.csv` | 81 | 16 | Gender and empowerment scorecard |
| 40 | Select Family Planning Indicators Data for Kenya | `select-family-planning-indicators_national_ken.csv` | 73 | 13 | Curated family planning overview |
| 41 | Select Nutrition Indicators Data for Kenya | `select-nutrition-indicators_national_ken.csv` | 59 | 12 | Curated nutrition overview |
| 42 | Select Child Mortality Indicators Data for Kenya | `select-child-mortality-indicators_national_ken.csv` | 70 | 5 | Curated mortality overview |
| 43 | Select Education Indicators Data for Kenya | `select-education-indicators_national_ken.csv` | 52 | 8 | Curated education overview |
| 44 | COVID-19 Prevention Data for Kenya | `covid-19-prevention_national_ken.csv` | 126 | 19 | WASH/crowding prevention context |
| 45 | COVID-19 Additional factors Data for Kenya | `covid-19-additional-factors_national_ken.csv` | 113 | 22 | Household, age, autonomy, digital, violence context |

## Suggested Dashboard Pages

| Page | Main visual | Supporting elements | Data source emphasis |
|---|---|---|---|
| Overview | KPI cards plus pinned trends | latest snapshot table, headline text | Quickstats, selected indicators |
| All Indicators | searchable catalogue table | filters, exports, pinning | all 46 resources |
| Domain Detail | domain-specific chart grid | resource metadata, data table | one resource at a time |
| Indicator Detail | trend line with CI ribbon | breakdown charts, row-level table | one indicator at a time |
| Compare Indicators | multi-line or indexed trend chart | correlation and shared-year table | selected indicators |
| Data Quality | availability heatmap | missingness, denominators, CI flags | all resources |
| Story Pages | curated dashboards by theme | narrative text, notes, exports | grouped resources |

## UI and Layout Plan

- Header:
  - dashboard title
  - last data refresh date
  - source attribution
  - global search
- Global filters:
  - survey year range
  - domain group
  - survey type
  - characteristic category
  - total/preferred estimate
- Main navigation:
  - Overview
  - Domains
  - All Indicators
  - Stories
  - Compare
  - Data Quality
  - Downloads
- Mobile behavior:
  - collapse domain navigation into a searchable drawer
  - KPI cards become a horizontal scroll or two-column grid
  - tables keep sticky first column and horizontal scroll
- Accessibility:
  - no color-only status encoding
  - plain-language labels
  - chart table fallback
  - tooltips for confidence intervals, denominators, and preferred estimates

## Text and Narrative Strategy

Use short dashboard text that helps interpretation without burying users.

Recommended text blocks:

- Overview summary:
  - 3-5 bullets generated from largest changes and latest-year values
- Domain summaries:
  - "This domain contains X indicators across Y rows, covering YEAR-YEAR. Latest available estimates are from YEAR."
- Indicator notes:
  - "This indicator is available for N survey years."
  - "Confidence intervals are available/not available for this indicator."
  - "This view is filtered to total estimates."
- Data caveats:
  - "DHS surveys are not annual. Lines connect survey observations only."
  - "Some indicators use different time windows; compare only matching breakdown labels."
  - "National data only. Use the separate HDX subnational DHS dataset for county or regional mapping."

## Implementation Notes

Suggested stack if this is built in R/Shiny:

- Data ingestion:
  - `httr2` or `curl` for downloads
  - `readr` for CSV parsing
  - `dplyr`, `tidyr`, `stringr`, `lubridate` for normalization
- Dashboard:
  - `shiny`
  - `bslib`
  - `plotly` or `echarts4r` for interactive plots
  - `DT` or `reactable` for searchable tables
  - `pins` or local RDS/parquet cache for processed datasets
- Data storage:
  - raw CSV files in `data-raw/dhs_hdx/`
  - processed RDS/parquet files in `data/` or `inst/extdata/`
  - manifest in `data-raw/dhs_hdx_manifest.csv`

Suggested stack if this is built as a static/front-end dashboard:

- Data prep:
  - R or Python preprocessing into tidy CSV/parquet/JSON
- Front end:
  - React or Svelte
  - Apache ECharts, Plotly, or Observable Plot
  - DuckDB-WASM or Arrow for local analytical filtering if the dataset grows

## Build Sequence

1. Create a download script that reads the HDX package API and downloads all 46 CSV resources.
2. Build a resource manifest and validate row counts, indicator counts, columns, and latest survey years.
3. Normalize all resources into one long indicator table.
4. Create a hand-curated SDG/Vision 2030 indicator mapping table.
5. Create the indicator catalogue, latest estimates, trend deltas, quality flags, and SDG/Vision status tables during preprocessing.
6. Build the SDG and Vision 2030 Status Overview first, using precomputed status labels and evidence-strength flags.
7. Build detailed SDG pages for SDG 2, 3, 4, 5, 6, 7/9, 10/11, and 16 where DHS has direct or proxy evidence.
8. Build the Vision 2030 Social Pillar page and a companion Evidence Gaps page.
9. Build the All Indicators catalogue with search, filters, SDG/Vision tags, and export.
10. Build reusable `ggiraph` chart components for trend, bar, stacked bar, heatmap, KPI card, SDG status card, and data table.
11. Build domain detail pages from a config table rather than hard-coding 46 separate pages.
12. Add story pages for fertility/family planning, child health, nutrition, HIV, malaria, WASH, education, gender, and COVID context.
13. Add data-quality and metadata views.
14. Add source attribution, refresh date, SDG/Vision caveats, and download links.
15. Test against indicators with sparse years, multiple breakdowns, confidence intervals, duplicate appearances across resources, and proxy-only SDG mappings.

## Minimum Viable Dashboard

The first useful version should include:

- SDG/Vision 2030 Status Overview with all 17 SDG cards
- detailed SDG pages for SDG 2, 3, 4, 5, 6, and 7/9 proxy infrastructure
- Vision 2030 Social Pillar scorecard
- Evidence Gaps page for SDGs and Vision themes DHS cannot answer
- Overview page with 12-16 pinned DHS evidence KPIs
- Domain Explorer covering all 46 resources
- searchable All Indicators table with SDG/Vision tags
- generic Indicator Detail page
- trend chart with CI support
- raw row table and CSV export
- metadata/caveat panel

## Comprehensive Version

The full version should add:

- thematic story pages
- indicator comparison workspace
- availability and data quality heatmaps
- curated policy scorecards
- automatic narrative summaries
- saved/pinned indicator sets
- exportable charts and filtered datasets
- optional subnational extension using the separate HDX Kenya subnational DHS dataset

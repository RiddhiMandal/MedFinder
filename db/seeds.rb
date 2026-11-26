# Demo knowledge base for the supplement agent.
#
# Everything here was written for this project: the brands and products are
# fictional, and the articles are short general summaries, not medical advice.
# Re-running `bin/rails db:seed` replaces the catalog.

Interaction.delete_all
Article.delete_all
Product.delete_all

# --- Knowledge base articles --------------------------------------------------

articles = [
  {
    title: "Magnesium: comparing the common forms",
    topic: "magnesium glycinate citrate oxide threonate sleep cramps constipation",
    body: <<~TEXT,
      Magnesium supplements differ mainly in the compound the magnesium is bound to.
      Magnesium glycinate (bisglycinate) is well absorbed and gentle on the stomach; it is
      often chosen for evening use and by people who get loose stools from other forms.
      Magnesium citrate is also well absorbed but has a mild laxative effect, so it is
      sometimes used for occasional constipation. Magnesium oxide contains a lot of
      magnesium per pill but is poorly absorbed and is the most likely to cause diarrhea.
      Magnesium L-threonate is marketed for cognitive support; evidence is still early.
      The tolerable upper intake level for supplemental magnesium in adults is about
      350 mg per day; higher doses commonly cause digestive upset. People with kidney
      disease should not take magnesium without medical supervision.
    TEXT
    sources: "NIH Office of Dietary Supplements, Magnesium fact sheet"
  },
  {
    title: "Vitamin D3, and why it is often paired with K2",
    topic: "vitamin d d3 k2 bone immune winter deficiency",
    body: <<~TEXT,
      Vitamin D3 (cholecalciferol) is the form the skin makes in sunlight and generally
      raises blood levels more effectively than D2. Many people in northern latitudes run
      low in winter. Common maintenance doses for adults are 600 to 2,000 IU per day; the
      upper limit for adults is 4,000 IU per day unless a clinician directs otherwise,
      usually after a blood test. Vitamin D is fat soluble, so taking it with a meal that
      contains fat improves absorption. It is often sold with vitamin K2 (as MK-7) because
      K2 helps direct calcium into bone; evidence for the combination is promising but
      not conclusive. People taking warfarin should not start vitamin K products without
      talking to their prescriber.
    TEXT
    sources: "NIH Office of Dietary Supplements, Vitamin D fact sheet"
  },
  {
    title: "Omega-3 fish oil: EPA, DHA and what to look for",
    topic: "omega-3 fish oil epa dha heart triglycerides algae vegan",
    body: <<~TEXT,
      Fish oil supplies the omega-3 fatty acids EPA and DHA. The number that matters on a
      label is the combined EPA plus DHA per serving, not the total "fish oil" amount.
      Typical general-health doses are 250 to 1,000 mg of EPA plus DHA per day; higher
      doses are used under medical supervision for high triglycerides. Triglyceride-form
      and re-esterified oils are well absorbed. Taking it with food reduces fishy burps.
      Algae oil is a plant-based source of DHA and EPA suitable for vegans. High doses
      can add to the effect of blood thinners.
    TEXT
    sources: "NIH Office of Dietary Supplements, Omega-3 fact sheet"
  },
  {
    title: "Iron: absorption, timing and side effects",
    topic: "iron ferrous bisglycinate anemia fatigue absorption vitamin c calcium",
    body: <<~TEXT,
      Iron is best absorbed on an empty stomach and with vitamin C. Calcium, coffee, tea
      and some antacids reduce absorption, so separate them from iron by about two hours.
      Ferrous sulfate is inexpensive but commonly causes constipation and nausea; iron
      bisglycinate is usually better tolerated at a similar effective dose. Iron should not
      be taken "just in case": too much iron is harmful, and fatigue has many causes. A
      blood test (ferritin) is the usual way to decide whether iron is needed. Keep iron
      supplements away from children; accidental overdose is dangerous.
    TEXT
    sources: "NIH Office of Dietary Supplements, Iron fact sheet"
  },
  {
    title: "Vitamin B12 for vegans, vegetarians and older adults",
    topic: "b12 cobalamin methylcobalamin cyanocobalamin vegan vegetarian energy metformin",
    body: <<~TEXT,
      Vitamin B12 is found naturally almost only in animal foods, so people who eat a
      vegan diet need a supplement or fortified foods. Absorption also falls with age and
      with long-term use of metformin or acid-reducing medicines. Cyanocobalamin is stable,
      inexpensive and well studied; methylcobalamin is an active form some people prefer.
      Both correct deficiency. B12 has no established upper limit because excess is
      excreted, but very high doses offer no extra benefit to people who are not deficient.
    TEXT
    sources: "NIH Office of Dietary Supplements, Vitamin B12 fact sheet"
  },
  {
    title: "Melatonin for sleep: dose and timing",
    topic: "melatonin sleep insomnia jet lag shift work",
    body: <<~TEXT,
      Melatonin is a hormone that signals night to the body. It is most useful for shifting
      the timing of sleep, such as jet lag or a delayed sleep schedule, and less so for
      general insomnia. Low doses (0.5 to 3 mg) taken 30 to 60 minutes before the target
      bedtime often work as well as higher doses with less morning grogginess. It is meant
      for short-term use. It can add to the effect of sedatives, and people on blood
      thinners, immunosuppressants or diabetes medication should check with a clinician.
      Magnesium glycinate and good sleep habits are common non-hormonal alternatives.
    TEXT
    sources: "NIH National Center for Complementary and Integrative Health, Melatonin"
  },
  {
    title: "Probiotics: strains matter",
    topic: "probiotic gut digestion antibiotics lactobacillus bifidobacterium ibs",
    body: <<~TEXT,
      Probiotic effects are specific to the strain, so a product's label should list
      strains (for example Lactobacillus rhamnosus GG), not just species. Evidence is best
      for reducing antibiotic-associated diarrhea; for general "gut health" it is mixed.
      When taken with antibiotics, separate the doses by a few hours. Some products need
      refrigeration. People who are severely immunocompromised should avoid probiotics
      unless their care team recommends one.
    TEXT
    sources: "NIH National Center for Complementary and Integrative Health, Probiotics"
  },
  {
    title: "Zinc and copper balance",
    topic: "zinc copper immune cold balance long-term",
    body: <<~TEXT,
      Zinc supports immune function, and zinc lozenges started early may shorten a cold
      slightly. The adult upper limit is 40 mg per day. Long-term zinc above that can cause
      copper deficiency, which is why some formulas include a small amount of copper.
      Zinc can reduce absorption of some antibiotics (tetracyclines and quinolones), so
      doses should be separated. Taking zinc on an empty stomach can cause nausea.
    TEXT
    sources: "NIH Office of Dietary Supplements, Zinc fact sheet"
  },
  {
    title: "St. John's wort interacts with many medications",
    topic: "st johns wort mood depression interactions birth control antidepressant",
    body: <<~TEXT,
      St. John's wort is an herbal product used for low mood. It speeds up the breakdown of
      many drugs in the liver, which can make them less effective. Known problems include
      hormonal birth control, some HIV and transplant medications, warfarin and digoxin.
      Combined with SSRIs or other antidepressants it can cause serotonin syndrome. Anyone
      taking prescription medication should speak with a pharmacist or prescriber first,
      and depression should be assessed by a clinician rather than self-treated.
    TEXT
    sources: "NIH National Center for Complementary and Integrative Health, St. John's Wort"
  },
  {
    title: "Calcium: food first, and split the dose",
    topic: "calcium bone osteoporosis carbonate citrate",
    body: <<~TEXT,
      Most people can meet calcium needs from food; supplements are used to fill a gap.
      The body absorbs about 500 mg or less at a time, so larger amounts are split across
      the day. Calcium carbonate is inexpensive and should be taken with food; calcium
      citrate can be taken with or without food and is better for people on acid reducers.
      Calcium reduces absorption of iron and thyroid medication, so separate them.
    TEXT
    sources: "NIH Office of Dietary Supplements, Calcium fact sheet"
  },
  {
    title: "Ashwagandha and stress",
    topic: "ashwagandha stress adaptogen anxiety sleep thyroid",
    body: <<~TEXT,
      Ashwagandha is an herb studied for stress and sleep, with modest benefits in short
      trials of standardized root extracts. It is not recommended in pregnancy. It may raise
      thyroid hormone levels and can interact with thyroid medication, sedatives and
      immunosuppressants. Rare cases of liver injury have been reported, so stop it if
      symptoms such as yellowing skin or dark urine appear.
    TEXT
    sources: "NIH Office of Dietary Supplements, Ashwagandha fact sheet"
  },
  {
    title: "Prenatal vitamins: folate and iodine",
    topic: "prenatal pregnancy folate folic acid methylfolate iodine choline",
    body: <<~TEXT,
      Folic acid (400 to 800 mcg per day) is recommended for anyone who could become
      pregnant, starting at least a month before conception, to reduce the risk of neural
      tube defects. Methylfolate is an alternative form. A prenatal should also contain
      iodine; many do not contain enough choline or omega-3, which are sometimes taken
      separately. Avoid high-dose vitamin A (retinol) in pregnancy. Prenatal choices are
      best made with a prenatal care provider.
    TEXT
    sources: "CDC, Folic Acid; NIH Office of Dietary Supplements"
  },
  {
    title: "How to read a supplement label",
    topic: "label quality third party tested gmp certification dose serving",
    body: <<~TEXT,
      Check the serving size first: a "1,000 mg" claim may require three capsules. Look at
      the amount of the active compound, not the total weight of the ingredient (for
      example, elemental magnesium or EPA plus DHA). Third-party testing seals from
      independent labs indicate the product contains what it claims and was screened for
      contaminants. Be cautious with proprietary blends, which hide individual amounts.
    TEXT
    sources: "FDA, Dietary Supplements: what you need to know"
  },
  {
    title: "When to talk to a practitioner first",
    topic: "safety pregnancy medication children kidney liver surgery",
    body: <<~TEXT,
      Talk to a healthcare practitioner before starting supplements if you are pregnant or
      breastfeeding, take prescription medication, have kidney or liver disease, are
      scheduled for surgery, or are choosing products for a child. Supplements are
      regulated less strictly than medicines, and "natural" does not mean free of side
      effects or interactions.
    TEXT
    sources: "FDA, Dietary Supplements: what you need to know"
  }
]

articles.each { |attrs| Article.create!(attrs) }

# --- Product catalog (fictional brands) ---------------------------------------

products = [
  [ "Magnesium Glycinate 120 mg", "Northfield Naturals", "Minerals", "capsule", "2 capsules (240 mg elemental magnesium)", 2499, true,
   "Magnesium bisglycinate chelate", "Gentle, well-absorbed magnesium for evening use.", "magnesium glycinate sleep relaxation cramps" ],
  [ "Magnesium Citrate Powder", "Clearwater Labs", "Minerals", "powder", "1 scoop (300 mg elemental magnesium)", 1899, true,
   "Magnesium citrate, citric acid, natural lemon flavour", "Drink mix; mild laxative effect at higher doses.", "magnesium citrate constipation powder" ],
  [ "Magnesium Oxide 400", "ValueWell", "Minerals", "tablet", "1 tablet (400 mg elemental magnesium)", 899, false,
   "Magnesium oxide", "Budget high-dose tablet. Lower absorption.", "magnesium oxide budget" ],
  [ "D3 2000 IU + K2", "Northfield Naturals", "Vitamins", "softgel", "1 softgel", 2199, true,
   "Vitamin D3 (cholecalciferol) 2,000 IU, vitamin K2 (MK-7) 100 mcg, olive oil", "Daily D3 with K2 in an oil base.", "vitamin d d3 k2 bone immune" ],
  [ "Vitamin D3 1000 IU Drops", "Little Sprout", "Vitamins", "liquid", "1 drop", 1599, true,
   "Vitamin D3 1,000 IU, MCT oil", "Unflavoured drops; easy for people who dislike pills.", "vitamin d d3 drops liquid" ],
  [ "Triple Strength Omega-3", "Coastline Nutrition", "Omega-3s", "softgel", "2 softgels (1,100 mg EPA+DHA)", 3499, true,
   "Fish oil concentrate (anchovy, sardine) in triglyceride form; EPA 650 mg, DHA 450 mg; lemon oil", "Concentrated, third-party tested fish oil.", "omega-3 fish oil epa dha heart" ],
  [ "Algae Omega", "Greenleaf Botanics", "Omega-3s", "softgel", "2 softgels (500 mg EPA+DHA)", 3999, true,
   "Algal oil (Schizochytrium sp.); DHA 335 mg, EPA 165 mg; plant-based softgel", "Vegan omega-3 from algae.", "omega-3 algae vegan dha epa plant-based" ],
  [ "Gentle Iron 25 mg", "Clearwater Labs", "Minerals", "capsule", "1 capsule", 1699, true,
   "Iron (as ferrous bisglycinate) 25 mg, vitamin C 60 mg", "Non-constipating iron with vitamin C.", "iron bisglycinate gentle anemia" ],
  [ "Iron 65 mg (Ferrous Sulfate)", "ValueWell", "Minerals", "tablet", "1 tablet", 699, true,
   "Iron (as ferrous sulfate) 65 mg", "Inexpensive standard-dose iron.", "iron ferrous sulfate budget" ],
  [ "Methyl B12 1000 mcg", "Greenleaf Botanics", "Vitamins", "lozenge", "1 lozenge", 1499, true,
   "Vitamin B12 (methylcobalamin) 1,000 mcg, mannitol", "Dissolvable B12; vegan.", "b12 methylcobalamin vegan energy" ],
  [ "B12 500 mcg", "ValueWell", "Vitamins", "tablet", "1 tablet", 599, true,
   "Vitamin B12 (cyanocobalamin) 500 mcg", "Simple, low-cost B12.", "b12 cyanocobalamin vegan budget" ],
  [ "Sleep Low-Dose Melatonin 1 mg", "Northfield Naturals", "Sleep", "tablet", "1 tablet", 1099, true,
   "Melatonin 1 mg", "Low dose for timing sleep; take 30 to 60 minutes before bed.", "melatonin sleep jet lag low dose" ],
  [ "Calm Night", "Coastline Nutrition", "Sleep", "capsule", "2 capsules", 2799, true,
   "Magnesium glycinate 200 mg elemental, L-theanine 200 mg, glycine 1 g", "Non-hormonal evening blend.", "sleep magnesium theanine glycine non-hormonal" ],
  [ "Daily Probiotic LGG", "Clearwater Labs", "Digestive Health", "capsule", "1 capsule (10 billion CFU)", 2999, true,
   "Lactobacillus rhamnosus GG 10 billion CFU", "Single, well-studied strain; shelf stable.", "probiotic lgg gut antibiotics" ],
  [ "Zinc 15 mg + Copper", "Northfield Naturals", "Minerals", "capsule", "1 capsule", 1299, true,
   "Zinc (as bisglycinate) 15 mg, copper (as bisglycinate) 1 mg", "Balanced zinc with copper for long-term use.", "zinc copper immune" ],
  [ "Ashwagandha KSM Root Extract", "Greenleaf Botanics", "Stress & Mood", "capsule", "1 capsule (600 mg)", 2599, false,
   "Ashwagandha root extract (standardized to 5% withanolides) 600 mg", "Standardized root extract.", "ashwagandha stress adaptogen sleep" ],
  [ "Prenatal Complete", "Little Sprout", "Prenatal", "capsule", "2 capsules", 3299, true,
   "Methylfolate 1,000 mcg DFE, iodine 150 mcg, iron 18 mg, choline 100 mg, vitamin D3 1,000 IU, B12 10 mcg", "Prenatal with active folate and iodine.", "prenatal pregnancy folate iodine" ],
  [ "Calcium Citrate + D", "ValueWell", "Minerals", "tablet", "2 tablets (500 mg calcium)", 1199, true,
   "Calcium (as citrate) 500 mg, vitamin D3 400 IU", "Can be taken with or without food.", "calcium citrate bone vitamin d" ]
]

products.each do |name, brand, category, form, serving, price, stock, ingredients, description, tags|
  Product.create!(name:, brand:, category:, form:, serving_size: serving, price_cents: price, in_stock: stock,
                  ingredients:, description:, tags:)
end

# --- Interactions ---------------------------------------------------------------

[
  [ "fish oil (omega-3)", "warfarin (blood thinner)", "moderate", "High doses of omega-3 may add to the anticoagulant effect and raise bleeding risk. Monitoring is advised." ],
  [ "vitamin k", "warfarin (blood thinner)", "high", "Vitamin K directly counteracts warfarin. Changes in vitamin K intake need prescriber guidance and INR monitoring." ],
  [ "st. john's wort", "ssri antidepressant", "high", "Risk of serotonin syndrome. Do not combine without a prescriber." ],
  [ "st. john's wort", "birth control pill", "high", "St. John's wort can reduce the effectiveness of hormonal contraception." ],
  [ "iron", "calcium", "low", "Calcium reduces iron absorption. Take them at least two hours apart." ],
  [ "iron", "levothyroxine (thyroid medication)", "moderate", "Iron reduces absorption of levothyroxine. Separate by at least four hours." ],
  [ "calcium", "levothyroxine (thyroid medication)", "moderate", "Calcium reduces absorption of levothyroxine. Separate by at least four hours." ],
  [ "zinc", "antibiotics (tetracycline, quinolone)", "moderate", "Zinc binds these antibiotics and lowers their absorption. Separate the doses." ],
  [ "magnesium", "antibiotics (tetracycline, quinolone)", "moderate", "Magnesium binds these antibiotics. Take the antibiotic at least 2 hours before or 4 to 6 hours after magnesium." ],
  [ "melatonin", "sedatives", "moderate", "May add to drowsiness. Avoid combining without medical advice." ],
  [ "ashwagandha", "levothyroxine (thyroid medication)", "moderate", "Ashwagandha may raise thyroid hormone levels; thyroid tests may need monitoring." ],
  [ "probiotic", "antibiotics (tetracycline, quinolone)", "low", "Antibiotics can kill probiotic bacteria. Take the probiotic a few hours after the antibiotic." ]
].each do |a, b, severity, summary|
  Interaction.create!(substance_a: a, substance_b: b, severity:, summary:)
end

puts "Seeded #{Article.count} articles, #{Product.count} products, #{Interaction.count} interactions."

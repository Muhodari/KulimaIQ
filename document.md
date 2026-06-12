AFRICAN LEADERSHIP UNIVERSITY
BSc. in Software Engineering


KulimaIQ: A Machine Learning-Powered Mobile Agricultural
Intelligence System for Crop Disease Detection Among
Smallholder Farmers in Eastern Africa


A Capstone Research Proposal

SAGE MUHODARI

Supervisor:

Emmanuel Adjei

Date:

1st June 2026

TABLE OF CONTENTS

CHAPTER ONE: INTRODUCTION	6
1.1 Introduction and Background	6
1.2 Problem Statement	7
4. 1.3 Project's Main Objective	8
6. 1.3.1 Specific Objectives	8
1.4 Research Questions	8
1.5 Project Scope	9
1.6 Significance and Justification	9
1.7 Research Budget	10
1.8 Research Timeline	10
CHAPTER TWO: LITERATURE REVIEW	12
2.1 Introduction	12
2.2 Overview of Existing Systems	12
2.3 Review of Related Work	13
2.3.1 Structural Vulnerability of Smallholder Farmers	13
2.3.2 Pest and Disease Burden	13
2.3.3 Digital Agriculture and Artificial Intelligence	14
2.3.4 Technology Adoption and Behavioral Considerations	14
2.4 Summary of Reviewed Literature	14
2.5 Strengths and Weaknesses of Existing Systems	15
2.6 General Comment and Conclusion	15
CHAPTER THREE: SYSTEM ANALYSIS AND DESIGN	16
3.1 Introduction	16
3.2 Research Design and Development Model	16
3.3 Population and Sampling	16
3.4 System Architecture	17
3.5 Data Definition and Acquisition	17
3.6 Machine Learning Training Pipeline	18
3.7 Model Comparison and Architecture Selection	18
3.8 Data Collection Methods	18
3.9 Data Analysis Methods	19
3.10 Development Tools	19
3.11 Ethical Considerations	19
REFERENCES	21





LIST OF ACRONYMS AND ABBREVIATIONS
AI – Artificial Intelligence
ANN – Artificial Neural Network
BXW – Banana Xanthomonas Wilt
CMD – Cassava Mosaic Disease
CNN – Convolutional Neural Network
FAO – Food and Agriculture Organization
FGD – Focus Group Discussion
IPCC – Intergovernmental Panel on Climate Change
IoT – Internet of Things
MLN – Maize Lethal Necrosis
ML – Machine Learning
PICSA – Participatory Integrated Climate Services for Agriculture
RAWARD – Rwanda Agriculture and Animal Resources Development Board
SMS – Short Message Service
SPSS – Statistical Package for the Social Sciences
WFP – World Food Programme

ABSTRACT
Agriculture remains the economic backbone of Eastern Africa, yet smallholder farmers in Rwanda, Kenya, Uganda, and Tanzania continue to suffer preventable crop losses of 20–40% annually due to plant diseases, pest infestations, and climate variability (Savary et al., 2019; IPCC, 2022). Existing digital solutions such as PlantVillage and iCow address specific dimensions of this challenge but fail to deliver an integrated, low-bandwidth system combining real-time crop disease detection, localized climate advisories, and market linkage within a single mobile platform. This research proposes KulimaIQ, a machine learning-powered Android application designed to reduce crop losses among smallholder farmers through early disease detection using convolutional neural networks (CNNs). The project will adopt a mixed-methods research design, combining quantitative evaluation of CNN model performance metrics (accuracy, precision, recall, and F1-score targeting a minimum of 80% validation accuracy) with qualitative investigation of usability, trust, and adoption behavior among 30–50 farmers in Byumba Sector, Northern Province, Rwanda, over a three-month pilot period. It is hypothesized that farmers equipped with KulimaIQ will demonstrate at least a 15% reduction in delayed disease response time compared to baseline practices. Findings are expected to demonstrate the technical feasibility of mobile CNN-based diagnostics in low-resource settings and provide evidence-based design recommendations for context-specific agricultural AI systems in Eastern Africa. This research contributes to advancing food security, climate resilience, and sustainable rural development aligned with national and global development goals.

CHAPTER ONE: INTRODUCTION
1.1 Introduction and Background
In Sub-Saharan Africa, agriculture is still the primary source of economic and social development. Smallholder farmers are an important source of food, jobs and GDP in Eastern African nations including Rwanda, Kenya, Uganda, and Tanzania. As reported by Lowder et al. (2016), smallholder farms account for more than 80% of agricultural fields in developing nations, but they employ insufficient technological, and financial, resources. Agriculture contributes to more than 25% of GDP in Rwanda and employs most of the rural population, but productivity on land is much less than the global average. Crop losses due to pests and plant diseases in the world are estimated to be around 30-40% each year (Savary et al., 2019). The losses are especially high in Eastern Africa where they do not get detected in time and extension services are limited. Infections with diseases like Maize Lethal Necrosis (MLN), Cassava Mosaic Disease (CMD) and Banana Xanthomonas Wilt (BXW) have led to significant losses in staple food crops where millions of people rely on for their livelihood.
Traditional extension services have been the main sources of disease identification and management tips to smallholder farmers in Eastern Africa in the past. In-person farm visits by agricultural extension officers and training farmers in their communities are becoming increasingly ineffective due to the magnitude of the problem, the speed at which pests migrate as a result of climate change and the scarcity of extension staff. For instance, in Rwanda the Twigire Muhinzi extension model is implemented with farmer promoters at the cell and village levels, which still poses a challenge to reach all farmers in time to prevent spread of disease. Digital agricultural solutions are showing potential as a complement to the traditional solutions. Plant disease detection using image based deep learning techniques has been proven to have high potential for plant disease diagnostic applications (Mohanty et al., 2016), and mobile phones are very widely used in rural Rwanda, making them a suitable distribution platform to reach and deliver AI based advisory systems.
Agriculture also faces risks which are exacerbated by climate change. The Intergovernmental Panel on Climate Change (IPCC, 2022) reports that there has been a rise in rainfall variability, longer droughts and higher temperatures over Eastern Africa. From 2020 to 2023, the Horn of Africa (HAN) experienced consecutive years of poor rains, resulting in high levels of food insecurity (WFP, 2023). Changes in climate provide opportunities for pests and diseases to flourish, like Fall Armyworm affecting maize production in East Africa (Day et al., 2017). This research thus proposes a machine learning-based mobile system for agricultural intelligence (KulimaIQ), which specifically aims to provide early detection of crop diseases, while simultaneously providing localized climate advisory support as an integrated feature to enhance the capacity of the smallholder to make decisions and strengthen their capacity for climate resilience.
1.2 Problem Statement
Agriculture provides the livelihoods for most rural households in the Eastern Africa region, but losses of crops from plant diseases and pest infestation are too high. According to Savary et al. (2019), crop pathogens cost commerce up to 40% in crop losses, greatly harming crops in the developing world. The capacity of smallholder farmers to timely access information, detect crop diseases at early stages with high precision, and implement timely interventions to control and reduce the impact of crop diseases is limited in Eastern Africa, which can worsen yield reduction and promote the spread of the disease. Food availability remains under threat in Rwanda by diseases like CMD and MLN; and there are no specific and available diagnostic tools in the country so that many farmers follow trial and error methods or wait for hours to ask for advice from extension officers. These delays result in food and income insecurity, as well as increased poverty in rural areas.
Currently available digital solutions try to solve agricultural inefficiencies, but are not yet capable of doing so. PlantVillage has applied AI to identifying diseases through smartphone photos and has shown technical feasibility but fails to fully integrate climate forecasting in the local area and digital market connectivity in a lightweight, low bandwidth environment. iCow provides SMS services for agricultural advisory services in Kenya, but no machine learning to aid in early disease diagnosis using image data. Moreover, most of the AgriTech platforms are not designed to work in low resource rural areas with limited Internet connectivity, lower-end Android devices and differences in digital literacy. Aker (2011) observes that context-specificity is crucial when it comes to context, as tools are going to be adopted and are going to be effective in the real world in developing areas. Implementation of a unified, AI-based low-bandwidth crop disease detection system geared towards the needs of Eastern African smallholder production is still a long way off.
Technologically, current deep-learning-based plant disease detection models have been effective in laboratory-controlled settings but may fail to perform well in field environments due to factors such as image quality, lighting conditions, plant species, disease stages, etc. (Mwebaze & Biehl, 2019; Ramcharan et al., 2019). This is an important barrier between training and field performance that remains to be solved. Further, there is a gap in empirical testing and validation of AI-based agricultural systems specifically in Rwandan smallholder settings, which are largely different from those in other regions. This work therefore introduces KulimaIQ: a mobile application that combines CNN-based crop disease detection, localized climate advisory and market linkage within a single offline capable Android platform and is designed and piloted in Rwanda's Byumba Sector to solve the above problems.
1.3 Project's Main Objective
The general objective of this project is to design, develop and test KulimaIQ – a mobile agricultural intelligence platform with machine learning capabilities that can help smallholder farmers combat crop diseases in the early stages using a CNN-based image diagnostic system running on affordable Android-powered devices to help reduce crop losses and hence support food security and climate smart agriculture in the Byumba Sector in Rwanda.
1.3.1 Specific Objectives
To conduct a review of the literature in crop disease detection systems, deep learning applications in agricultural and technology adoption among smallholder farmers in Eastern Africa and to gather primary insights from farmers and extension officers in Byumba Sector to facilitate the design of KulimaIQ.
To create a functioning prototype for KulimaIQ- a cross-platform Android application using flutter framework for prototyping a functional application with a trained Convolutional Neural Network (CNN) for detecting at least 3 major crop diseases (Cassava Mosaic Disease, Maize Lethal Necrosis and Banana Xanthomonas Wilt) and localised climate advisory features, with a minimum validation accuracy of 80% for the target diseases.
To implement a three-month pilot with 30–50 smallholder farmers in Byumba Sector, and gather measurable evidence that such farmers can use the system, and that they see a reduction in delayed disease response time of at least 15% compared to baseline practices.
1.4 Research Questions
What is the ability of a low cost, deployed convolutional neural network on an Android smartphone to detect prevalent crop diseases from farmer gathered leaf images, in a real field setting in Byumba Sector, Rwanda?
Do localised climate advisory capabilities when embedded in KulimaIQ enhance smallholder farmer decision making about timing of planting and disease management?
What are the usability factors, behavioral drivers and contextual barriers affecting the adoption and continued use of KulimaIQ for smallholder farmers in the Byumba Sector?
1.5 Project Scope
Geographically this study will be conducted in Byumba Sector, Northern Province, Rwanda. The limited scope is important for feasibility given time and resources, and is representative of a testbed to test KulimaIQ core features in a rainfed smallholder farming context. The target population should be 30-50 smallholder farmers with maize, cassava or banana crops who have been identified as being at risk of the priority diseases targeted by the CNN model and of being significant to household food security in their region.
The system will primarily be used for disease detection using images, and will only secondarily have the weather advisory functions and a basic produce listing. The CNN will be trained for the detection of 3 crop diseases: Cassava Mosaic Disease (CMD), Maize Lethal Necrosis (MLN) and Banana Xanthomonas Wilt (BXW). The pilot will run for three months, enough to gain some initial feedback on usability and performance. This initial study leaves out nationwide rollout, advanced predictive yield modelling, full market e-commerce integration and extensive policy evaluation, which are reserved for future work.
1.6 Significance and Justification
KulimaIQ is a potential game-changer for smallholder farmers in Eastern Africa, helping to decrease preventable crop losses. A simple improvement in yield loss due to earlier recognition of disease can significantly contribute to food security and income stability of those households relying on subsistence and small-scale commercial farming. This research has multiple stakeholders, including farmers, agricultural cooperatives, decision-makers, and digital innovation ecosystems, benefiting from it.
This project is expected to close a critical evidence gap in the field literature on the performance and usability of an AI-driven disease detection tool in low-resource environments by bringing empirical evidence on these features under real field conditions in Rwanda. The results will provide empirical design guidance for future AgriTech systems with the goal of closing the train-to-field performance and adoption gap with smallholder communities.
This study not only makes a significant practical contribution to the field of agriculture but also serves an academic purpose by advancing technological innovations in low-bandwidth settings and highlighting the intersection between technology and rural development. It also supports SDG 2 (Zero Hunger), SDG 13 (Climate Action) and SDG 8 (Decent Work and Economic Growth) by building resilience of vulnerable smallholder farming communities..
1.7 Research Budget

Item
Description
Estimated Cost
Data Collection Transport
Field travel to Byumba Sector (x8 visits)
80,000 RWF
Smartphone for Testing
Android device for prototype deployment
120,000 RWF
Mobile Data / Internet
Data bundles for API calls and model hosting
30,000 RWF
Printing & Stationery
Survey forms, consent forms, field materials
15,000 RWF
Enumerator Allowances
2 assistants for pilot data collection
60,000 RWF
Cloud Hosting (3 months)
Model API and app backend hosting
45,000 RWF
Contingency (10%)
Unforeseen expenses
35,000 RWF
TOTAL


385,000 RWF


1.8 Research Timeline
The project will be executed over a twelve-week period structured across three phases: design, development and piloting, and reflection. The Gantt chart below presents the schedule of activities.

Activity
Wk 1
Wk 2
Wk 3
Wk 4
Wk 5
Wk 6
Wk 7
Wk 8
Wk 9
Wk 10
Wk 11
Wk 12
Literature Review & Stakeholder Consultation
●
●
●


















System Requirements & Design


●
●
●
















Dataset Collection & Preprocessing




●
●
●














CNN Model Training & Validation






●
●
●
●










App Development (Flutter)








●
●
●
●








Integration & Testing












●
●
●






Pilot Study (Byumba Sector)














●
●
●




Data Analysis & Reporting
















●
●
●


Final Documentation & Submission


















●
●
●



CHAPTER TWO: LITERATURE REVIEW
2.1 Introduction
This chapter reviews existing software-related literature to establish the theoretical and empirical foundations for KulimaIQ. The review was conducted by systematically searching for peer-reviewed studies, technical reports, and institutional publications related to crop disease detection systems, deep learning and machine learning in agriculture, climate-adaptive digital tools, and technology adoption among smallholder farmers in sub-Saharan Africa. Indexed platforms including Google Scholar, IEEE Xplore, Frontiers in Plant Science, and the ACM Digital Library were explored using search terms such as 'crop disease detection mobile', 'CNN plant disease classification', 'digital agriculture sub-Saharan Africa', and 'technology adoption smallholder farmers'. Approximately 45 papers and reports were identified, from which 20 were selected for in-depth review based on their direct relevance to the project's focus on crop diseases, AI-based mobile systems, and Eastern African agricultural contexts. The review is organized thematically to cover: structural vulnerability of smallholder farmers, pest and disease burden, digital agriculture and AI applications, existing software systems, and technology adoption considerations.
2.2 Overview of Existing Systems
Several software systems currently address aspects of crop disease detection and agricultural advisory for smallholder farmers. PlantVillage, developed by Penn State University and deployed via its Nuru mobile application, offers CNN-based diagnosis of cassava diseases using smartphone images. Nuru achieves diagnostic accuracy exceeding that of extension officers under field conditions and operates fully offline — a critical feature for low-connectivity rural settings (Mrisho et al., 2020). However, PlantVillage Nuru is focused primarily on cassava, limiting coverage of other critical Eastern African crops such as maize and banana. Furthermore, it does not integrate localized climate advisory or market linkage functionalities within the same platform.
iCow is an SMS-based agricultural advisory platform operating in Kenya that delivers text-based information on livestock and crop management to smallholder farmers via basic mobile phones. While it provides accessible information delivery, iCow lacks any image-based diagnostic capability and does not leverage machine learning for disease identification. It also relies on farmer-initiated queries rather than proactive, contextually triggered alerts.
Agromonitoring and similar precision farming platforms offer satellite imagery and remote sensing data for field monitoring, but these systems are designed for larger commercial farms with reliable internet connectivity and are not optimized for the device constraints and literacy levels typical of smallholder users in Eastern Africa. Collectively, these systems demonstrate the viability of digital agricultural tools but confirm the gap KulimaIQ seeks to fill: a single, integrated, offline-capable platform combining CNN-based disease detection for multiple crops, localized climate advisories, and market connectivity, designed specifically for low-resource smallholder environments in Rwanda.
2.3 Review of Related Work
2.3.1 Structural Vulnerability of Smallholder Farmers
Lowder, Skoet, and Raney (2016) use global agricultural census data to demonstrate that smallholder farms represent more than 80% of farms in developing countries. These farms dominate food production yet lack access to modern technology, credit, and extension services — a structural disadvantage that any agricultural innovation must explicitly address. The Food and Agriculture Organization (FAO, 2021) expands this analysis by identifying digital agriculture and innovation as critical to achieving food security and sustainable development goals, underscoring the relevance of AI-based tools like KulimaIQ for transforming smallholder systems.
2.3.2 Pest and Disease Burden
Savary et al. (2019) use global crop-loss databases and probabilistic modeling to estimate that pests and pathogens account for 20–40% yield losses in major crops worldwide, with disproportionate impacts in developing regions. This quantification establishes the measurable scale of the problem that KulimaIQ's disease diagnostic module is designed to address. Day et al. (2017) document the rapid spread of Fall Armyworm across Sub-Saharan Africa, demonstrating the need for early warning and rapid diagnostic tools. Mwebaze and Biehl (2019) develop a mobile deep learning model for cassava disease diagnosis in Tanzania, demonstrating technical feasibility but also highlighting that model accuracy can drop significantly when moving from curated datasets to variable field environments — a key challenge KulimaIQ must address through diverse training data and iterative field validation. Mrisho et al. (2020) evaluate PlantVillage Nuru under real East African field conditions and confirm that smartphone-based CNN models can outperform human diagnosticians when properly designed and calibrated. Ramcharan et al. (2019) further document the train-to-field performance gap, emphasizing the need for models trained on heterogeneous, farmer-captured images.
2.3.3 Digital Agriculture and Artificial Intelligence
Wolfert et al. (2017) analyze big data and IoT technologies in smart farming, providing architectural guidance for integrated advisory platforms that combine multiple data streams. While their examples reflect Global North contexts, the conceptual frameworks inform KulimaIQ's design as a system integrating images, climate information, and market data into a coherent decision-support interface. Kamilaris and Prenafeta-Boldú (2018) conduct a systematic review of deep learning applications in agriculture, confirming high diagnostic performance in controlled conditions while highlighting implementation challenges in low-resource environments. Liakos et al. (2018) review machine learning applications in yield prediction and crop monitoring, confirming the potential for ML to support farm management decisions and informing KulimaIQ's algorithm selection. Mohanty et al. (2016) demonstrate that CNNs trained on the PlantVillage dataset can achieve over 99% accuracy under laboratory conditions, establishing a theoretical performance ceiling while also underscoring that real-world deployment demands additional robustness measures.
2.3.4 Technology Adoption and Behavioral Considerations
Rose et al. (2016) demonstrate that technological effectiveness alone does not guarantee farmer adoption; usability, trust, relevance, and co-design processes are equally critical. These insights directly guide KulimaIQ's emphasis on intuitive interfaces, locally relevant content, and participatory design. Aker (2011) shows that mobile phones can significantly enhance smallholder decision-making and market efficiency in developing regions, supporting KulimaIQ's choice of Android mobile as the primary delivery channel. Fabregas, Kremer, and Schilbach (2019) review digital agricultural extension interventions and find mixed effectiveness depending on contextual adaptation and delivery mechanisms, reinforcing the importance of iterative user testing and local partnerships. Tesfaye et al. (2023) provide Rwanda-specific evidence showing that smallholder farmers are more likely to adopt digital climate services when they are accurate, user-tailored, and integrated with market information — features that directly inform KulimaIQ's design priorities. Steinke et al. (2019) demonstrate that lightweight household-specific profiling can substantially improve the relevance of mobile advisory recommendations, suggesting design strategies for tailoring KulimaIQ's outputs to different farmer segments.
2.4 Summary of Reviewed Literature
The reviewed literature collectively establishes that: (1) smallholder farmers in Eastern Africa face severe, quantifiable crop losses from preventable diseases; (2) CNN-based mobile systems are technically feasible for disease detection but require field-adapted training data and offline functionality; (3) existing systems address isolated dimensions of the problem but lack integration; and (4) human factors including trust, usability, and contextual fit are as important as technical accuracy in determining real-world adoption and impact.
2.5 Strengths and Weaknesses of Existing Systems
System
Strengths
Weaknesses
PlantVillage / Nuru
Offline CNN-based diagnosis; validated in East Africa; high accuracy vs. extension officers
Cassava-only focus; no climate advisory; no market linkage; limited to one crop type
iCow
Accessible via basic phones; SMS delivery suits low-literacy users; established user base in Kenya
No ML/image-based diagnosis; reactive not proactive; Kenya-centric; no disease-specific detection
Agromonitoring
Advanced satellite and IoT data; suitable for precision farming; broad crop coverage
Requires reliable internet and high-end devices; designed for large commercial farms; not adapted for smallholders


2.6 General Comment and Conclusion
The literature confirms that AI-driven mobile crop disease detection is technically feasible and urgently needed in Eastern Africa. However, critical gaps persist: most systems target a single crop, lack integration with climate and market data, are not validated under real smallholder field conditions in Rwanda, and fail to adequately address the behavioral dimensions of adoption. KulimaIQ addresses these gaps by delivering an integrated, offline-capable, multi-crop disease detection platform designed through participatory processes with farmers in Byumba Sector. The theoretical frameworks of climate resilience, precision agriculture systems, and technology adoption collectively inform both the technical architecture and the user-centered design approach of KulimaIQ.

CHAPTER THREE: SYSTEM ANALYSIS AND DESIGN
3.1 Introduction
This chapter describes the system analysis and design approach for KulimaIQ. It outlines the research methodology, development model, system architecture, data flow, machine learning pipeline, and UML diagrams that guide the construction of the prototype. The design approach is informed by findings from the literature review, particularly the need for offline functionality, low-bandwidth operation, intuitive interfaces, and robust CNN-based disease detection validated under Eastern African field conditions. The methodology combines mixed-methods research with an agile development process to ensure that both technical performance and user-centered design requirements are met iteratively throughout the project.
3.2 Research Design and Development Model
This study will adopt a mixed-methods research design combining quantitative and qualitative approaches. Quantitative elements will address model performance metrics and structured survey outcomes, while qualitative elements will explore farmer perceptions, usability experiences, and adoption barriers through semi-structured interviews, focus group discussions, and field observations. This design is appropriate because KulimaIQ sits at the intersection of technical AI innovation and human behavior in resource-constrained settings.
The development model will follow an Agile iterative approach, structured across three phases: (1) Design Phase — translating literature review insights and stakeholder consultations into system requirements and low-fidelity mockups; (2) Development and Pilot-Testing Phase — building the KulimaIQ prototype, training and validating the CNN model, and exposing farmers and extension officers to the tool under real field conditions over four to six weeks; and (3) Reflection and Refinement Phase — analyzing collected data, identifying technical and user-experience strengths and limitations, and generating recommendations for improved system design and future impact evaluations.
3.3 Population and Sampling
The target population consists of smallholder farmers in Byumba Sector, Northern Province, Rwanda, cultivating maize, cassava, or banana crops. A non-probability purposive sampling strategy will be used, targeting 30–50 farmers who grow at least one of the target crops, own or have regular access to an Android smartphone, and are willing to participate in prototype training and testing. Additionally, 5–10 agricultural extension officers (Twigire Muhinzi farmer promoters) active in the study area will be recruited. Diversity in gender, age, and farm size will be actively sought to ensure a range of smallholder perspectives is captured in the pilot.
3.4 System Architecture
KulimaIQ is built on a modular, layered mobile-first architecture designed for low-bandwidth and offline operation. The system consists of four primary layers:
Frontend (Mobile Client): A cross-platform Android application built using Flutter. The UI is designed for low-literacy users, using icon-driven navigation, Kinyarwanda language support, and minimal cognitive load. Core features include image capture for disease diagnosis, climate advisory display, and a basic produce market listing.
AI Inference Engine: A TensorFlow Lite (TFLite) CNN model deployed directly on the device for offline inference. The model is optimized for low-memory Android devices using quantization techniques, enabling disease classification without internet connectivity.
Backend API (FastAPI): A lightweight RESTful API handles model updates, climate data retrieval from the Rwanda Meteorological Agency, and optional market data synchronization when connectivity is available. The API is containerized using Docker for consistent deployment.
Data Layer: A local SQLite database on the device stores diagnosis history, farmer profile data, and cached advisory content. A PostgreSQL database on the server stores aggregated anonymized usage data and model feedback loops for periodic model retraining.
3.5 Data Definition and Acquisition
The CNN model will be trained on a curated dataset combining publicly available plant disease image repositories (including PlantVillage and iPlant datasets) with locally collected field images from Byumba Sector. A minimum of 3,000 labeled images per disease class will be targeted, representing three crop diseases: Cassava Mosaic Disease (CMD), Maize Lethal Necrosis (MLN), and Banana Xanthomonas Wilt (BXW), plus healthy leaf classes for each crop. Images will be collected under varied lighting conditions, angles, and disease progression stages to improve field robustness. Dataset splits will follow an 80/10/10 train/validation/test ratio. All locally collected images will be accompanied by informed consent from farmers and will be anonymized before use in model training.
3.6 Machine Learning Training Pipeline
The machine learning pipeline follows a structured path from raw data to a deployable on-device model. Raw images are first preprocessed (resized to 224×224 pixels, normalized, augmented with random flipping, rotation, brightness adjustment, and zoom) to increase training robustness. Transfer learning will be applied using MobileNetV2 as the base architecture, selected for its balance of accuracy and computational efficiency on mobile hardware. The top classification layers will be fine-tuned on the curated crop disease dataset. Model performance will be benchmarked against alternative architectures including EfficientNet-Lite and a custom lightweight CNN to justify the final model selection. After training, the best-performing model will be converted to TensorFlow Lite format and quantized to reduce model size and improve inference speed on low-end Android devices. The full pipeline will be managed in Google Colab or a local Python environment using TensorFlow 2.x.
3.7 Model Comparison and Architecture Selection
To identify the optimal model architecture for KulimaIQ's deployment constraints, the following CNN architectures will be benchmarked on the curated dataset:
Architecture
Justification
Role
MobileNetV2 (TFLite)
Primary candidate: high accuracy-to-size ratio; designed for mobile deployment; TFLite-native
Baseline for comparison
EfficientNet-Lite0
Strong accuracy with efficient scaling; pre-trained on ImageNet; TFLite-compatible
Compared vs. MobileNetV2
Custom Lightweight CNN
Designed from scratch for target crop diseases; smallest model size
Baseline fallback


Model selection will be based on a composite score weighing validation accuracy (weight: 40%), model size in MB (weight: 30%), inference speed on a mid-range Android device (weight: 20%), and F1-score across disease classes (weight: 10%).
3.8 Data Collection Methods
Primary data collection will include structured pre- and post-use questionnaires administered to participating farmers (before and after a four-to-six week pilot period), semi-structured interviews with 8–12 farmers and extension officers, one or two focus group discussions (6–10 participants each), non-participant field observations of KulimaIQ use in real agricultural settings, and anonymized prototype usage logs. Secondary data will include the existing literature review, Rwanda climate services documentation, and RAWARD agricultural extension policy documents. All instruments will be developed in English and translated into Kinyarwanda, expert-reviewed for content validity, and pilot-tested with 3–5 participants before full deployment.
3.9 Data Analysis Methods
Quantitative data will be analyzed using descriptive statistics (frequencies, percentages, means, and standard deviations) for demographic and perception variables. Model performance will be evaluated using accuracy, precision, recall, F1-score, and confusion matrices for each disease class. Pre-post comparisons of self-reported disease response timing will be computed as indicative evidence and interpreted cautiously given the small non-random sample. Qualitative data from interviews, focus groups, and observations will undergo thematic analysis following systematic coding, theme development, and triangulation with quantitative findings to provide a comprehensive understanding of KulimaIQ's technical performance and user experience.
3.10 Development Tools
Frontend: Flutter (Dart) — cross-platform Android application development
Machine Learning: TensorFlow 2.x / TensorFlow Lite — CNN model training and mobile deployment
Model Training Environment: Google Colab / Python 3.10 with NumPy, OpenCV, Pandas, Scikit-learn
Backend API: FastAPI (Python) — RESTful API for model updates and climate data retrieval
Database: SQLite (on-device) / PostgreSQL (server-side)
Containerization: Docker — consistent backend deployment
Version Control: GitHub — code and model versioning
Survey & Analysis: Google Forms / Microsoft Excel / SPSS — data collection and statistical analysis
Design & Prototyping: Figma — UI/UX wireframes and low-fidelity mockups
3.11 Ethical Considerations
Ethical approval will be sought from the relevant institutional review board at the university and local authorities in Rwanda prior to any data collection. All participants will provide informed consent in Kinyarwanda before participating. Consent procedures will include reading forms aloud for participants with limited literacy. Personal identifiers will be removed from all datasets and replaced with codes; reports will present only aggregated or anonymized data. Digital data will be stored on password-protected, encrypted storage accessible only to the researcher and authorized supervisors. The study will avoid exposing participants to physical, psychological, or social harm; sensitive questions will be asked only when necessary. Data collection activities will be scheduled to avoid interfering with critical farming activities. Findings will be shared with participating farmers and extension officers in accessible formats, including Kinyarwanda summaries and demonstration sessions.

REFERENCES
Aker, J. C. (2011). Dial 'A' for agriculture: Using information and communication technologies for agricultural extension in developing countries. Agricultural Economics, 42(6), 631–647. https://doi.org/10.1111/j.1574-0862.2011.00545.x
Day, R., Abrahams, P., Bateman, M., Beale, T., Clottey, V., Cock, M., & Witt, A. (2017). Fall armyworm: Impacts and implications for Africa. Outlooks on Pest Management, 28(5), 196–201. https://doi.org/10.1564/v28_oct_02
Fabregas, R., Kremer, M., & Schilbach, F. (2019). Realizing the potential of digital development: The case of agricultural advice. Annual Review of Economics, 11, 163–190. https://doi.org/10.1146/annurev-economics-080218-030327
Food and Agriculture Organization. (2021). The state of food and agriculture 2021. FAO. https://www.fao.org/3/cb4476en/cb4476en.pdf
Gebru, B. M., Ichoku, C. M., & Hoffman, F. M. (2021). Climate variability and smallholder vulnerability in East Africa. Climate Risk Management, 33, 100347. https://doi.org/10.1016/j.crm.2021.100347
Intergovernmental Panel on Climate Change. (2022). Climate change 2022: Impacts, adaptation and vulnerability. IPCC. https://www.ipcc.ch/report/ar6/wg2/
Kamilaris, A., & Prenafeta-Boldú, F. X. (2018). Deep learning in agriculture: A survey. Computers and Electronics in Agriculture, 147, 70–90. https://doi.org/10.1016/j.compag.2018.02.016
Liakos, K. G., Busato, P., Moshou, D., Pearson, S., & Bochtis, D. (2018). Machine learning in agriculture: A review. Sensors, 18(8), 2674. https://doi.org/10.3390/s18082674
Lowder, S. K., Skoet, J., & Raney, T. (2016). The number, size, and distribution of farms worldwide. World Development, 87, 16–29. https://doi.org/10.1016/j.worlddev.2015.10.041
Mohanty, S. P., Hughes, D. P., & Salathé, M. (2016). Using deep learning for image-based plant disease detection. Frontiers in Plant Science, 7, 1419. https://doi.org/10.3389/fpls.2016.01419
Mrisho, L. M., Mbilinyi, N. A., Ndalahwa, M., Ramcharan, A. M., Kehs, A. K., McCloskey, P. C., Murithi, H., Hughes, D. P., & Legg, J. P. (2020). Accuracy of a smartphone-based object detection model, PlantVillage Nuru, in identifying the foliar symptoms of the viral diseases of cassava. Frontiers in Plant Science, 11, 590889. https://doi.org/10.3389/fpls.2020.590889
Mwebaze, E., & Biehl, M. (2019). A mobile-based deep learning model for cassava disease diagnosis in Tanzania. Frontiers in Plant Science, 10, 272. https://doi.org/10.3389/fpls.2019.00272
Ramcharan, A. M., McCloskey, P., Baranowski, K., Mbilinyi, N., Mrisho, L., Ndalahwa, M., Legg, J., & Hughes, D. P. (2019). A mobile-based deep learning model for cassava disease diagnosis. Frontiers in Plant Science, 10, 272. https://doi.org/10.3389/fpls.2019.00272
Rose, D. C., Sutherland, W. J., Parker, C., Lobley, M., Winter, M., Morris, C., Twining, S., Ffoulkes, C., Amano, T., & Dicks, L. V. (2016). Decision support tools for agriculture: Towards effective design and delivery. Agricultural Systems, 149, 165–174. https://doi.org/10.1016/j.agsy.2016.09.009
Savary, S., Willocquet, L., Pethybridge, S. J., Esker, P., McRoberts, N., & Nelson, A. (2019). The global burden of pathogens and pests on major food crops. Nature Ecology & Evolution, 3, 430–439. https://doi.org/10.1038/s41559-018-0793-y
Steinke, J., van Etten, J., Müller, A., Ortiz-Crespo, B., van de Gevel, J., Silvestri, S., & Priebe, J. (2019). Targeting the right farmers when promoting agricultural innovations in sub-Saharan Africa: Costs and benefits of different targeting strategies. World Development, 124, 104643. https://doi.org/10.1016/j.worlddev.2019.104643
Tesfaye, A., Hansen, J., Kagabo, D., Birachi, E., Radeny, M., & Solomon, D. (2023). Modeling farmers' preference and willingness to pay for improved climate services in Rwanda. Environment and Development Economics, 28(4), 368–386. https://doi.org/10.1017/S1355770X22000286
Wolfert, S., Ge, L., Verdouw, C., & Bogaardt, M. J. (2017). Big data in smart farming. Agricultural Systems, 153, 69–80. https://doi.org/10.1016/j.agsy.2017.01.023
World Food Programme. (2023). Horn of Africa drought situation report. WFP. https://www.wfp.org/emergencies/horn-africa-crisis

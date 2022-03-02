# Portfolio Assessment Tool for Fires (Open-Source & Near-Real-Time)

The app can be found [online](https://frederickf.shinyapps.io/asset-based-portfolio-fire-risk-assessment/).


## About
This tool is a prototype that allows stakeholders to assess the risk of fires (especially wildfires) in their financial portfolio. 
Stakeholders can select or upload their portfolio and identify which physical assets of the companies in their portfolio are currently
in the proximity of fires. The aim is to identify among thousands of physical assets in a financial portfolio those that deserve special
attention when analysing fire risk. This tool does not take into account the characteristics and vulnerability of an asset and does not
calculate/forecast material damage or financial costs. The features and advantages of this prototype shown here are the use of granular,
near real-time and open-source data and being transparent in terms of data sources, assumptions and modelling. This tool has been developed
independently and is not associated with any organisation.<br>
This version is still a *prototype* that will see further improvements in the next months.

More information can be found online on the app under the _Approach_ tab.

The layout and structure of this Shiny App are inspired by Joe Cheng's 'superzip' example https://shiny.rstudio.com/gallery/superzip-example.html.


## Instructions

You can run the app locally by running ```app.R```. In this script, you can also choose which datasets should be updated. Usually, it is sufficient to only update the data concerning wildfires as the other datasets do not change significantly over time. Also, the preparation of the other datasets takes some time (1-2 hours). All necessary data sets are available in the folder ```data``` except the data of the Global Legal Identifier Initiative as these files are too large. However, running the app is possible as these files are only used in the preparation process. Preparation scripts for the different datasets can be found in the folder ```scripts```.

### Please feel free to send feedback and questions to frederick.fabian@aol.com

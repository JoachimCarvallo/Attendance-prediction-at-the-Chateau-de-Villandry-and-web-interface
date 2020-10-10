# Attendance prediction at the Chateau de Villandry and web interface

## Description :
The objective of this project is to produce a model that predict the number of visitors at the Château de Villandry for a given day. This model must be accompanied by a web interface in order to be able to access its predictions easily. The prediction will be based on weather data obtained by webscraping the Météo France website, as well as all the relevant informations on the day in question, such as the season, the day of the week, holiday periods, public holidays, etc.

[Here is a link to check the web app.](https://joachimcarvallo.shinyapps.io/pred-freq-villandry/) It's in french because it is meant to be used by a french user. 

## Quick overview of the project :

### 1. Webscraping of historical weather data

On the [Météo France's web site](https://meteofrance.com/), there use to be freely available data for every recorded day at a meteo station close to Villandry (20 km). This service is no longer available. The R library "rvest" is used to gather all the data available between 1991 and 2019. Missing data is completed with the data found on this [web site](https://www.historique-meteo.net/france/centre/tours/). The objective was to obtain a weather database, in the same format as that which can be obtained on the Météo France website for the weather forecast of the next day, in order to be able to make real predictions with the future model.

The variables of the finale database are :
- General description of the weather of the day : A combination of the weather informations available at 10 a.m., 1 p.m. and 4 p.m. (for exemple : rainy, sunny, covered, covered and sunny, etc)
- Description of the weather at 1pm (the descriptions of the weather at 10 a.m. and 4 p.m. had too mutch missing values)
- Weather grade fo the day : A quantitative representation of the quality of the weather (only depending on weather description at 10 a.m., 1 p.m. and 4 p.m.)
- Maximum temperature of the day
- Precipitation : the number of millimeters of rain that fell

We also had sunshine duration but we couldn't use it because Météo France does not provide a forecast for it. 

### 2. Data preparation

The decisions taken in this section are mostly informed by the experience of the director of the Château de Villandry. 
First of all, we put together the number of visitors at Villandry, the weather data, the holiday's periods data and the public holidays data. Those two last datasets are available on https://www.data.gouv.fr/. Then a few corrections are applied to the data : public holidays on weekends are not relevant, removal of the anomaly of June 2016 (the castle had to close because of risks of flooding), etc. 

**New variables :** month, day of the week, information on long weekends, special events and attendance of the last few days. 

**Transfomation of the variable to explain :** We will first create a relevant curve of the normal seasonnality in Villandry. We want to get a curve as smooth as possible, that represent, for a given day of the year, the normal frequentation (thus without knowing if it's a weekend, if there is a special event, if it's rainy, etc). Then, our variable to be explained will be the difference to the normal seasonality for each day.

To create this curve, first of all, we take the moving median over 7 days of the number of visitors. The aim of this moving median is to smooth the large spikes in the data (moving averge would have been to sensible to thoses spikes). Then we average the moving median for each day of the year, with more weight on recent years (linear progression of weights over the years from 1 to 27). Finaly,  we apply a final smoothing to the curve with a mobile average over 5 days. 

<img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/Animation%20Saisonality%20vs%20some%20years.gif" alt="Saisonality"	title="Animation of saisonality" width="750" height="375" style="text-align:center" />
### 3. A few statistics 


### 4. Selection of the best class of models

Results :

| Model                                        | RMSE          |
| -------------------------------------------- |:-------------:|
| Random Forest                                | 267.1256      |
| **Xgboost**                                  | **250.3095**  |
| CART                                         | 312.4196      |
| Linear regression                            | 312.459       |
| LASSO regression                             | 313.1293      |
| Linear regression with interaction variables | 269.3086      |
| LASSO regression with interaction variables  | 274.9008      |
| Ridge regression with interaction variables  | 267.2635      |
| Elastic net with interaction variables       | 272.9989      |

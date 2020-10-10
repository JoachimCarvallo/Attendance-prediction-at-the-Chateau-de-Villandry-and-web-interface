# Attendance prediction at the Chateau de Villandry and web interface

## Description :
The objective of this project is to produce a model that predict the number of visitors at the Château de Villandry for a given day. This model must be accompanied by a web interface in order to be able to access its predictions easily. The prediction will be based on weather data obtained by webscraping the Météo France website, as well as all the relevant informations on the day in question, such as the season, the day of the week, holiday periods, public holidays, etc.

[Here is a link to check the web app.](https://joachimcarvallo.shinyapps.io/pred-freq-villandry/) It's in french because it is meant to be used by a french user. 

## Project overview :

### 1. Webscraping of historical weather data

On the [Météo France's web site](https://meteofrance.com/), there use to be freely available data for every recorded day at a meteo station close to Villandry (20 km). This servie is no longer available. The R library "rvest" is used to gather all the data available between 1991 and 2019. Missing data is completed with the data found on this [web site](https://www.historique-meteo.net/france/centre/tours/). The objective was to obtain a weather database, in the same format as that which can be obtained on the Météo France website for the weather forecast of the next day, in order to be able to make real predictions with the future model.

The final database have :
- General description of the weather of the day : A combination of the weather information available at 10 a.m., 1 p.m. and 4 p.m. (for exemple : rainy, sunny, covered, covered and sunny,etc)
- Description of the weather at 1pm (the descriptions of the weather at 10 a.m. and 4 p.m. had too mutch missing values)
- Weather grade fo the day : A quantitative representation of the quality of the weather (only depending on weather description at 10 a.m., 1 p.m. and 4 p.m.)
- Maximum temperature of the day
- Precipitation : the number of millimeters of rain that fell

We also had sunshine duration but we couldn't use it because Météo France does not provide a forecast for it. 

### 2. Data preparation


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

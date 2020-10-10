# Attendance prediction at the Chateau de Villandry and web interface

## Description :
The objective of this project is to produce a model that predict the number of visitors at the Château de Villandry for a given day. This model must be accompanied by a web interface in order to be able to access its predictions easily. The prediction will be based on weather data obtained by webscraping the Météo France website, as well as all the relevant informations on the day in question, such as the season, the day of the week, holiday periods, public holidays, etc.

[Here is a link to check the app](https://joachimcarvallo.shinyapps.io/pred-freq-villandry/) It's in french because it is meant to be used by a french user. 

## Project overview :

### 1. Webscraping of historical weather data


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

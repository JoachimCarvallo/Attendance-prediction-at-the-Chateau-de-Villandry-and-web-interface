# Attendance prediction at the Chateau de Villandry and web interface

## Description :

<p align="justify">
The objective of this project is to produce a model that predict the number of visitors at the Château de Villandry for the next day. This model must be accompanied by a web interface in order to be able to access its predictions easily. The prediction will be based on weather data obtained by scraping the Météo France's website, as well as all the relevant informations on the day of interest, such as the season, the day of the week, holiday periods, public holidays, etc.
</p>
  
[Here is a link to check the web app.](https://joachimcarvallo.shinyapps.io/Prediction-frequentation-Villandry/) It is in french (as well as the variables names) because it is meant to be used by a french user. (The app isn't fully functional online, the automated web scraping of weather data on websites using javascript doesn't work on shinyapps' servers.)

## Overview of the project :

### 1. Webscraping of historical weather data

<p align="justify">
On the <a href="https://meteofrance.com/">Météo France's web site</a>, there use to be freely available data for every recorded day at a meteo station close to Villandry (20 km). This service is no longer available. The R library "rvest" is used to gather all the data available between 1991 and 2019. Missing data is completed with the data found on this <a href="https://www.historique-meteo.net/france/centre/tours/">web site</a>. The objective was to obtain a weather database, in the same format as that which can be obtained on the Météo France website for the weather forecast of the next day, in order to be able to make real predictions with the future model.
</p>

The variables of the finale database are :

- General description of the weather of the day : A combination of the weather informations available at 10 a.m., 1 p.m. and 4 p.m. (for exemple : rainy, sunny, covered, covered and sunny, etc)
- Description of the weather at 1pm (the descriptions of the weather at 10 a.m. and 4 p.m. had too mutch missing values)
- Weather grade fo the day : A quantitative representation of the quality of the weather (only depending on weather description at 10 a.m., 1 p.m. and 4 p.m.)
- Maximum temperature of the day
- Precipitation : the number of millimeters of rain that fell

We also had sunshine duration but we couldn't use it because Météo France does not provide a forecast for it. 

### 2. Data preparation

<p align="justify">
The decisions taken in this section are mostly informed by the experience of the director of the Château de Villandry. 
First of all, we put together the number of visitors at Villandry, the weather data, the holiday's periods data and the public holidays data. Those two last datasets are available on https://www.data.gouv.fr/. Then a few corrections are applied to the data : public holidays on weekends are not relevant, removal of the anomaly of June 2016 (the castle had to close because of risks of flooding), etc. 
</p>

**New variables :** month, day of the week, information on long weekends, special events and attendance of the last few days. 

<p align="justify"><strong>Transfomation of the variable to be explained :</strong> We will first create a relevant curve of the normal seasonnality in Villandry. We want to get a curve as smooth as possible, that represent, for a given day of the year, the normal frequentation (thus without knowing if it's a weekend, if there is a special event, if it's rainy, etc). Then, our variable to be explained will be the <strong>deviation from the seasonality of the number of visitors</strong>. 
</p>
<p align="justify">
To create this curve, first of all, we take the moving median over 7 days of the number of visitors. The aim of this moving median is to smooth the large spikes in the data (moving averge would have been to sensible to thoses spikes). Then we average the moving median for each day of the year, with more weight on recent years (linear progression of weights over the years from 1 to 27). Finaly,  we apply a final smoothing to the curve with a mobile average over 5 days. On the animation below, we can see the seasonality curve in red and the attendance for a few years in black :
</p>

<p align="center">
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/2.%20Data%20preparation/Animation%20Saisonality%20vs%20some%20years.gif" alt="Saisonality"	title="Animation of saisonality" width="750" height="375" />
</p>

<p align="justify">
Our result seems very satisfactory. It is consistent with the seasonality extraction method of the time series field, but seems more robust to noise in our data.
</p>
<p align="justify">
Finally, we remove the months from november to march to focus only on the main part of the season. Indeed, as we can see above, attendance over these months is very low, or even zero at times. We then split our database into two: 1991 to 2015 in the training set and 2016 to 2019 in the test set.
</p>

### 3. A few statistics 

In this section, we will try to see how our covariates relate to attendance, using bivariate graphs. 

<p align="justify">
<strong>Maximum temperature of the day :</strong> We can see on the first graph on the left the maximum temperature on the x-axis and the difference to seasonality on the y-axis, each point representing a day in our dataset. The variance of the deviation from seasonality is important but we can still distinguish an interesting trend : the frequentation tends to be more and more important compared to the seasonality when the temperature rises. This trend continues up to a threshold, around 28°C, from which the trend is reversed : each additional degree seems to reduce attendance. 
</p>

<p align="justify">
<strong>Precipitations :</strong> The second graph, on the right, is similar to the previous one but with precipitations. The x-axis is on a logarithmic scale and 1 corresponds to 0 mm fallen. We are also seeing an interesting trend : the more rain, the less frequentation. 
 </p>
<p align="justify">
Thoses two observations seem very intuitive because the Château de Villandry is particularly famous for its gardens : these trends are probably cause and effect links. However, they seem far from explaining all the variability of our attendance around seasonality.
</p> 

<p align="center">
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/3.%20A%20few%20statistics/Deviation%20from%20seasonality%20of%20the%20number%20of%20visitors%20against%20max%20temperature.jpeg" alt="Max temp"	title="Deviation from seasonality of the number of visitors against max temperature" width="390" height="260" />
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/3.%20A%20few%20statistics/Deviation%20from%20seasonality%20of%20the%20number%20of%20visitors%20against%20precipitation.jpeg" alt="Precipitations"	title="Deviation from seasonality of the number of visitors against precipitations" width="390" height="260" />  
</p>

<p align="justify">
<strong>Day of the week :</strong> On the first graph, on the left, we find on the x-axis the days of the week and on the y-axis a boxplot representing attendance. We observe that Monday tends to be below seasonality, then that attendance tends to increase gradually until Thursday. Friday is lower and almost back to Monday level. Then, the weekend logically tends to have a high attendance, in particular on Sundays.
</p>

<p align="justify">
<strong>Public holidays :</strong> On this last graph, we have the distribution of the deviation from the seasonality of normal days and public holidays. We can observe that the public holidays have, in general, a much greater attendance than the seasonality. However, they also have a larger variance than on other days.
</p>

<p align="center">
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/3.%20A%20few%20statistics/Deviation%20from%20seasonality%20of%20the%20number%20of%20visitors%20against%20day%20of%20the%20week.jpeg" alt="Days of the week"	title="Deviation from seasonality of the number of visitors against days of the week" width="390" height="260" />
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/3.%20A%20few%20statistics/Deviation%20from%20seasonality%20of%20the%20number%20of%20visitors%20against%20public%20holiday%20-%20Density.jpeg" alt="Public holidays"	title="Deviation from seasonality of the number of visitors against public holidays" width="390" height="260" />
</p>

We will not walk through all of the variables here, but these early observations look promising for modeling.

### 4. Selection of the best class of models

<p align="justify">
The objective of this part is to identify the class of models that performs best on our dataset. We will simply train a model of each classes, without much optimization, and compare they in order to identify the class that seem the more suited to our task. We will evaluate our models by their predictive qualities empirically on the test data set. The performance evaluation metric will be the ordinary least squares. 
</p>

<p align="justify">
Of course, we will not be able to consider all the classes of regression models. We will only focus on tree based methods as well as linear models. Specifically a CART, a random forest, and an XGBoost for tree-based methods. And linear regression, as well as its Ridge and LASSO extensions for linear models. For linear models, we will also feed them with "interaction variables" in addition to the starting variables in order to help them capture the interactions between variables (which they can't do on their own like tree-based methods). These simply consist of the product of all possible pairs of variables. Even if it's only second order interactions, the number of pairs is very large and therefore the selection of useful variables is very important. 
</p>

**Results :**

| Model                                        | RMSE          |
| -------------------------------------------- | :-----------: |
| CART                                         | 312.4196      |
| Random Forest                                | 267.1256      |
| **Xgboost**                                  | **250.3095**  |
| Linear regression                            | 312.459       |
| LASSO regression                             | 313.1293      |
| Linear regression with interaction variables | 269.3086      |
| LASSO regression with interaction variables  | 274.9008      |
| Ridge regression with interaction variables  | 267.2635      |
| Elastic net with interaction variables       | 272.9989      |
  
<p align="justify">
We can see that linear models without taking into account interactions, as well as the CART, are the least performing models. Then, we can see that the integration of interaction variables in linear models have greatly improved their performances. Among them, the best performing is the Ridge, which is at the same level as the Random Forest. However, the best performing model is the XGBoost.
</p>

### 5. Optimization and analysis of the model

<p align="justify">
In this part, we will start by optimizing the hyper-parameters of our XGBoost in order to minimize the RMSE criterion on our test set. Then, we will analyze the results of the model as well as its use of the covariates.
</p>

**Optimization :**

<p align="justify">
The XGBoost algorithm is laborious to optimize because of its numerous hyper-parameters. We proceed by random grid search, with 300 sets of hyper-parameters at first, then we focus on the most promising hyper-parameter area with a second grid of 300 sets of hyper-parameters. 
</p>

Best performing hyper-parameters set :

| num trees |  eta      | gamma    | max_depth | subsample | colsample_bytree | min_child_weight | **RMSE**     |
|:---------:|:---------:|:--------:|:---------:|:---------:|:----------------:|:----------------:|:------------:|
| 1279      |  0.01     | 0.74594  | 7         | 0.47517   | 0.53899          | 6.21274          | **240.0006** |



**Visualizations of our results :**

<p align="center">
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/5.%20Optimization%20and%20analysis%20of%20the%20model/Number%20of%20visitors%20-%20prediction%20vs%20real%20(2018).jpeg" alt="Predict"	title="Number of visitors - prediction vs real (2018)" width="800" height="400" />
</p>

<p align="justify">
The graph above shows attendance for 2016 in black and our model's predictions in green. We can see that our predictions are overall very satisfactory. The only big mistake made by the model is on the first weekend of July, which is a "Mille feux" weekend (the most popular event in Villandry), where the predictions are far below reality. For the years 2017 and 2018, we find the same pattern : the prediction error is low for "classic" days, however, for certain particular days, with spikes in attendance, the model makes significant errors. The model seems to identify these particular days but its predictions are sometimes very far from reality. It seems that the attendance on these particular days has a very large variance and that the variables available to us are not sufficient to explain all this variance, which sometimes leads to significant errors.
</p>

<img align="right" src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/5.%20Optimization%20and%20analysis%20of%20the%20model/Error%20as%20a%20proportion%20of%20the%20number%20of%20visitors.jpeg" alt="Error proportion"	title="Error as a proportion of the number of visitors" width="325" height="325" />

<p align="justify">
The second graph shows the distribution of errors on our test set, in proportion to the number of visitors of the day. We see that almost 1 out of 2 predictions has an error lower than 10%, almost 3 predictions out of 4 have an error of lower than 20%, and 9 out of 10 predictions have an error lower than 30%. 
</p>
<p align="justify">
Warning : we probably have a little bit overfitted our model on our test set by trying a lot of hyper-parameters and this distribution of error might be slightly worst for real predictions. To prevent this, we could have optimized our model by cross-validation and kept our test set only for the final evaluation. 
</p>


**Use of the covariates :**

<p align="justify">
The SHAP value, for SHapley Additive exPlanation, explains the output of a model as the sum of the effects of each of the explanatory variables. It is introduced by Scott Lundberg and Su-In Lee in “A Unified Approach to Interpreting Model Predictions”, where it’s very good properties are demonstrated.
</p>


<p align="justify">
First, by averaging the absolute values SHAP values over an entire dataset, we can get a measure of the overall importance of the variables.
</p>

<img align="left" src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/5.%20Optimization%20and%20analysis%20of%20the%20model/Importance%20of%20variables.jpeg" alt="Importance of variables"	title="Importance of variables" width="450" height="450" />

<p align="justify">
We will now try to understand the local impact of each of the variables, using the SHAP value. The SHAP value quantifies for each of the individuals in the test set, the impact on the prediction of each of the variables (in number of visitors). In the following graphs, each point represents an individual with on the x-axis the value of the variable for this individual, and on the y-axis the impact that this variable had on the prediction . We can generally observe a trend which makes the link between the values taken by the variable and its impact on the prediction. The variations around the trend are explained by the interactions that there may be between the different variables.
</p>

<p align="center">
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/5.%20Optimization%20and%20analysis%20of%20the%20model/Shap%20-%20Difference%20from%20the%20seasonality%20of%20the%20day%20before.jpeg" alt="Difference from seasonality"	title="Shap - Difference from the seasonality of the day before" width="390" height="260" />
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/5.%20Optimization%20and%20analysis%20of%20the%20model/Shap%20-%20Sunday.jpeg" alt="Sundays"	title="Shap - Sunday" width="260" height="260" />
</p>

<p align="center">
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/5.%20Optimization%20and%20analysis%20of%20the%20model/Shap%20-%20Weather%20grade.jpeg" alt="Weather grade"	title="Shap - Weather grade" width="390" height="260" />
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/5.%20Optimization%20and%20analysis%20of%20the%20model/Shap%20-%20Difference%20from%20the%20seasonality%20day%20-%207.jpeg" alt="Day - 7"	title="Shap - Difference from the seasonality day - 7" width="390" height="260" />
</p>

<p align="center">
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/5.%20Optimization%20and%20analysis%20of%20the%20model/Shap%20-%20Precipitations.jpeg" alt="Precipitations"	title="Shap - Precipitations" width="390" height="260" />
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/5.%20Optimization%20and%20analysis%20of%20the%20model/Shap%20-%20Maximum%20temperature.jpeg" alt="Maximum temperature"	title="Shap - Maximum temperature" width="390" height="260" />
</p>

To be continued...

### 6. R-shiny app 



# Attendance prediction at the Chateau de Villandry and web interface

## Description :

<p align="justify">
The objective of this project is to produce a model that predicts the number of visitors to the Château de Villandry for the next day. This model must be accompanied by a web interface to easily access its predictions. The prediction will be based on weather data obtained by scraping the Météo France website, as well as all relevant information for the day of interest, such as the season, day of the week, holiday periods, public holidays, etc.
</p>
  
[Here is a link to check the web app.](https://joachimcarvallo.shinyapps.io/Prediction-frequentation-Villandry/) It is in French (as well as the variable names) because it is intended to be used by a French user. (The app isn't fully functional online; the automated web scraping of weather data from websites using JavaScript doesn't work on shinyapps' servers.)

## Overview of the project :

### 1. Webscraping of historical weather data

<p align="justify">
On the <a href="https://meteofrance.com/">Météo France's web site</a>, there used to be freely available data for every recorded day at a meteorological station close to Villandry (20 km). This service is no longer available. The R library "rvest" is used to gather all the data available between 1991 and 2019. Missing data is completed with the data found on this <a href="https://www.historique-meteo.net/france/centre/tours/">web site</a>. The goal was to obtain a weather database in the same format as what can be obtained from the Météo France website for the weather forecast of the following day, in order to make real predictions with the future model.
</p>

The variables of the final database are:

- General description of the day's weather: A combination of the weather information available at 10 a.m., 1 p.m., and 4 p.m. (for example: rainy, sunny, cloudy, partly sunny, etc.)
- Description of the weather at 1 p.m. (the descriptions of the weather at 10 a.m. and 4 p.m. had too much missing data)
- Weather grade for the day: A quantitative representation of the quality of the weather (only depending on weather description at 10 a.m., 1 p.m., and 4 p.m.)
- Maximum temperature of the day
- Precipitation: the amount of rainfall in millimeters

Sunshine duration was also available but could not be used because Météo France does not provide a forecast for it.

### 2. Data preparation

<p align="justify">
The decisions taken in this section are mostly informed by the experience of the director of the Château de Villandry. First, we combined the number of visitors at Villandry, the weather data, the holiday periods data, and the public holidays data. These last two datasets are available on https://www.data.gouv.fr/. Then a few corrections are applied to the data: public holidays on weekends are not considered relevant, removal of the anomaly of June 2016 (the castle had to close due to flooding risks), etc.
</p>

**New variables :** month, day of the week, information on extended weekends, special events, and attendance of the previous days.

<p align="justify"><strong>Transfomation of the variable to be explained :</strong> We will first create a curve representing the normal seasonality at Villandry. We aim to obtain a curve as smooth as possible, representing the expected attendance for a given day of the year, without knowing if it's a weekend, there is a special event, it's rainy, etc. Then, our variable to be explained will be the <strong>deviation from the number of visitors' seasonality</strong>. 
</p>
<p align="justify">
To create this curve, we first take the moving median over 7 days of the number of visitors. The aim of this moving median is to smooth out the large spikes in the data (a moving average would have been too sensitive to these spikes). Then we average the moving median for each day of the year, with more weight on recent years (linear progression of weights over the years from 1 to 27). Finally, we apply a final smoothing to the curve with a moving average over 5 days. In the animation below, we can see the seasonality curve in red and the attendance for a few years in black:
</p>

<p align="center">
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/2.%20Data%20preparation/Animation%20Saisonality%20vs%20some%20years.gif" alt="Saisonality"	title="Animation of saisonality" width="750" height="375" />
</p>

<p align="justify">
Our result seems very satisfactory. It is consistent with the seasonality extraction method from the field of time series but appears more robust to noise in our data.
</p>
<p align="justify">
Finally, we exclude the months from November to March to focus only on the main part of the season. Indeed, as we can see in the animation above, the curve for the winter period is not smooth at all. It is not that we have no data, but rather that the attendance during this period is extremely variable and not dependent on the weather.
</p>

### 3. A few statistics 

In this section, we will examine how our covariates relate to attendance using bivariate graphs.

<p align="justify">
<strong>Maximum Temperature of the Day:</strong> On the first graph to the left, we can observe the maximum temperature on the x-axis and the difference from seasonality on the y-axis, with each point representing a day in our dataset. The variance of the deviation from seasonality is significant, but we can still discern an interesting trend: attendance tends to be increasingly significant compared to the seasonality as the temperature rises. This trend continues up to a threshold, around 28°C, beyond which the trend is reversed: each additional degree seems to reduce attendance.
</p>
<p align="justify">
<strong>Precipitations:</strong> The second graph, on the right, is akin to the previous one but with precipitation. The x-axis is on a logarithmic scale where 1 corresponds to 0 mm of rainfall. Here again, we observe an intriguing trend: more rain correlates with less frequentation.
</p>
<p align="justify">
These two observations seem very intuitive, as the Château de Villandry is particularly famous for its gardens: these trends are probably causal links. However, they seem far from explaining all the variability of our attendance around seasonality.
</p>

<p align="center">
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/3.%20A%20few%20statistics/Deviation%20from%20seasonality%20of%20the%20number%20of%20visitors%20against%20max%20temperature.jpeg" alt="Max temp"	title="Deviation from seasonality of the number of visitors against max temperature" width="390" height="260" />
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/3.%20A%20few%20statistics/Deviation%20from%20seasonality%20of%20the%20number%20of%20visitors%20against%20precipitation.jpeg" alt="Precipitations"	title="Deviation from seasonality of the number of visitors against precipitations" width="390" height="260" />  
</p>

<p align="justify">
<strong>Day of the Week:</strong> In the first graph on the left, we find on the x-axis the days of the week and on the y-axis, a boxplot representing attendance. We observe that Monday tends to be below seasonality, then attendance gradually increases until Thursday. Friday dips lower, nearly back to Monday’s level. Then, the weekend logically shows high attendance, especially on Sundays.
</p>
<p align="justify">
<strong>Public Holidays:</strong> This last graph shows the distribution of the deviation from the seasonality of normal days compared to public holidays. It’s evident that public holidays generally exhibit much greater attendance than the seasonality. However, they also show a larger variance than other days.
</p>

<p align="center">
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/3.%20A%20few%20statistics/Deviation%20from%20seasonality%20of%20the%20number%20of%20visitors%20against%20day%20of%20the%20week.jpeg" alt="Days of the week"	title="Deviation from seasonality of the number of visitors against days of the week" width="390" height="260" />
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/3.%20A%20few%20statistics/Deviation%20from%20seasonality%20of%20the%20number%20of%20visitors%20against%20public%20holiday%20-%20Density.jpeg" alt="Public holidays"	title="Deviation from seasonality of the number of visitors against public holidays" width="390" height="260" />
</p>

We will not review all of the variables here, but these initial observations look promising for modeling.

### 4. Selection of the best class of models

<p align="justify">
The objective of this part is to identify the class of models that performs best on our dataset. We will train a simple model of each class without extensive optimization and compare them to identify the most suited class for our task. We will assess our models by their predictive qualities empirically on the test dataset. The performance evaluation metric will be the Root Mean Square Error (RMSE).
</p>
<p align="justify">
We will not be able to consider all classes of regression models but will focus on tree-based methods and linear models. Specifically, we'll evaluate a CART, a Random Forest, and an XGBoost for tree-based methods. For linear models, we'll test linear regression and its Ridge and LASSO extensions. We'll also introduce "interaction variables" to the linear models to capture variable interactions (which they can't inherently manage like tree-based methods). These consist of the product of all possible pairs of variables. Even if it's only second-order interactions, the number of pairs is very large, making the selection of useful variables crucial.
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
Linear models without accounting for interactions, as well as the CART, are the least performing models. Then, we see that the inclusion of interaction variables in linear models has significantly improved their performance. Among them, the Ridge regression is the best performing, at the same level as the Random Forest. However, the XGBoost is the top-performing model.
</p>

### 5. Optimization and analysis of the model

<p align="justify">
In this part, we will begin by optimizing the hyperparameters of our XGBoost model to minimize the RMSE criterion on our test set. We will then analyze the results of the model, as well as its utilization of the covariates.</p>

**Optimization :**

<p align="justify">
The XGBoost algorithm is challenging to optimize due to its numerous hyperparameters. We proceed with a random grid search, starting with 300 sets of hyperparameters. We then narrow our focus to the most promising hyperparameter area with a second grid search of 300 sets.</p>

Best performing hyper-parameters set :

| num trees |  eta      | gamma    | max_depth | subsample | colsample_bytree | min_child_weight | **RMSE**     |
|:---------:|:---------:|:--------:|:---------:|:---------:|:----------------:|:----------------:|:------------:|
| 1279      |  0.01     | 0.74594  | 7         | 0.47517   | 0.53899          | 6.21274          | **240.0006** |



**Visualizations of our results :**

<p align="center">
  <img src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/5.%20Optimization%20and%20analysis%20of%20the%20model/Number%20of%20visitors%20-%20prediction%20vs%20real%20(2018).jpeg" alt="Predict"	title="Number of visitors - prediction vs real (2018)" width="800" height="400" />
</p>

<p align="justify">
The graph above shows attendance for 2016 in black and our model's predictions in green. Overall, our predictions are very satisfactory. The only significant error made by the model occurs on the first weekend of July, which is a "Mille Feux" weekend (the most popular event at Villandry), where the predictions are substantially below reality. For the years 2017 and 2018, the same pattern emerges: the prediction error is low for "classic" days, but for certain special days with spikes in attendance, the model makes significant errors. The model seems to recognize these particular days, but its predictions are sometimes far from reality. It appears that the attendance on these special days has a very high variance, and the variables at our disposal do not suffice to explain this variance fully, leading to substantial errors.
</p>

<img align="right" src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/5.%20Optimization%20and%20analysis%20of%20the%20model/Error%20as%20a%20proportion%20of%20the%20number%20of%20visitors.jpeg" alt="Error proportion"	title="Error as a proportion of the number of visitors" width="325" height="325" />

<p align="justify">
The second graph displays the distribution of errors on our test set as a proportion of the day's visitor count. We see that nearly 1 out of 2 predictions has an error lower than 10%, almost 3 out of 4 predictions have an error lower than 20%, and 9 out of 10 predictions have an error lower than 30%. 
</p>
<p align="justify">
Caution: We may have slightly overfitted our model to our test set by trying numerous hyperparameters, and the distribution of errors could be worse for actual predictions. To prevent this, we could have optimized our model using cross-validation and reserved our test set solely for the final evaluation.
</p>

**Use of the covariates :**

<p align="justify">
The SHAP value (SHapley Additive exPlanations) explains a model's output as the sum of the effects of each explanatory variable. Scott Lundberg and Su-In Lee introduced it in "A Unified Approach to Interpreting Model Predictions," demonstrating its excellent properties.
</p>
<p align="justify">
First, by averaging the absolute SHAP values over an entire dataset, we can obtain a measure of the overall importance of the variables.
</p>

<img align="center" src="https://github.com/JoachimCarvallo/Attendance-prediction-at-the-Chateau-de-Villandry-and-web-interface/blob/main/Plots/5.%20Optimization%20and%20analysis%20of%20the%20model/Importance%20of%20variables.jpeg" alt="Importance of variables"	title="Importance of variables" width="450" height="450" />

<p align="justify">
We will now try to understand the local impact of each of the variables, using the SHAP value. The SHAP value quantifies for each individual in the test set the impact that each variable has on the prediction. In the following graphs, each point represents an individual, with the x-axis showing the value of the variable for this individual, and the y-axis showing the impact that this variable had on the prediction (in number of visitors). We can generally observe a trend that links the values taken by the variable to its impact on the prediction. The variations around the trend are explained by the interactions that may exist between the different variables.
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



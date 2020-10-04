##################################################################################################
###########                   Webscraping of historical weather data                  ############
##################################################################################################

##### Loading libraries : 
library("rvest") #Library for web scraping 
library("dplyr") #Library for dataframes manipulations


##### Météo France historical Data :

# On Météo France's website, we have access to historical weather data near Villandry. 
# We have for every day since 1950 : max temperature, precipitation, sunshine, description of the weather at 10am, 1pm and 4 pm.
# (This service is no longer available)
meteo <- data.frame(DATE = rep(".", 31*12*29), meteo = rep(".", 31*12*29))
meteo$DATE <- as.character(meteo$DATE)
meteo$meteo <- as.character(meteo$meteo)

count <- 1
for (year in 1991:2019){
  print(year)
  for (month in 1:12){
    print(month)
    for (day in 1:31){
      meteo$DATE[count] <- paste(as.character(year),"-", as.character(month), "-", as.character(day), sep = "")
      url <- paste("http://www.meteofrance.com/climat/meteo-date-passee?lieuId=372610&lieuType=VILLE_FRANCE&date=", as.character(day),"-", as.character(month), "-", as.character(year), sep = "")
      meteo$meteo[count] <- html_text(html_node(read_html(url), xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "grids", " " ))]'))
      count <- count + 1
    }
  }
}
meteo$DATE <- as.Date(meteo$DATE)
meteo$DATE <- as.character(meteo$DATE)

# We find the same error for many lines. This section corrects the problem.
error <- "     Services et innovations Découvrez notre rapport annuel digital  Climat, météorologie, technologies ...        Exposition numérique 150 ans d'histoire du climat  A la reconquête d'observations anciennes pour mieux connaître le climat.    "
for(date in meteo$DATE[meteo$meteo == error]){
  url <- paste("http://www.meteofrance.com/climat/meteo-date-passee?lieuId=372610&lieuType=VILLE_FRANCE&date=", substr(date,9,10),"-", substr(date,6,7), "-", substr(date,1,4), sep = "")
  meteo$meteo[meteo$DATE == date] <- html_text(html_node(read_html(url), xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "grid-half", " " ))]'))
}
meteo <- meteo[!is.na(meteo$DATE),]

#load(file = "C:/Users/joach/OneDrive/Bureau/Visites Villandry/webscrap_meteofrance.Rda")

# Separation of our string containing data into variables :
meteo$Desc_10h <- "Pas d'obs"
meteo$Desc_13h <- "Pas d'obs"
meteo$Desc_16h <- "Pas d'obs"

temp <- strsplit(meteo$meteo, split = "   ")
for (i in 1:nrow(meteo)){
  if(length(temp[[i]]) == 5){
    meteo$Desc_10h[i] <- temp[[i]][2]
    meteo$Desc_13h[i] <- temp[[i]][3]
    meteo$Desc_16h[i] <- temp[[i]][4]
    meteo$meteo[i] <- temp[[i]][5]
  }
  if(length(temp[[i]]) == 4){
    if(temp[[i]][1] == "  10 h" & substr(temp[[i]][2], nchar(temp[[i]][2])-3 , nchar(temp[[i]][2])) == "13 h"){
      meteo$Desc_10h[i] <- temp[[i]][2]
      meteo$Desc_13h[i] <- temp[[i]][3]
      meteo$meteo[i] <- temp[[i]][4]
    }
    else if(temp[[i]][1] == "  10 h" & substr(temp[[i]][2], nchar(temp[[i]][2])-3 , nchar(temp[[i]][2])) == "16 h"){
      meteo$Desc_10h[i] <- temp[[i]][2]
      meteo$Desc_16h[i] <- temp[[i]][3]
      meteo$meteo[i] <- temp[[i]][4]
    }
    else {
      meteo$Desc_13h[i] <- temp[[i]][2]
      meteo$Desc_16h[i] <- temp[[i]][3]
      meteo$meteo[i] <- temp[[i]][4]
    }
  }
  if(length(temp[[i]]) == 3) {
    if(temp[[i]][1] == "  10 h"){
      meteo$Desc_10h[i] <- temp[[i]][2]
      meteo$meteo[i] <- temp[[i]][3]
    }
    else if(temp[[i]][1] == "  13 h"){
      meteo$Desc_13h[i] <- temp[[i]][2]
      meteo$meteo[i] <- temp[[i]][3]
    }
    else {
      meteo$Desc_16h[i] <- temp[[i]][2]
      meteo$meteo[i] <- temp[[i]][3]
    }
  }
  if(length(temp[[i]]) == 1){
    meteo$meteo[i] <- temp[[i]][1]
  }
}

meteo$Desc_10h <- as.factor(sub("  13 h", "", meteo$Desc_10h))
meteo$Desc_10h <- as.factor(sub("  16 h", "", meteo$Desc_10h))
meteo$Desc_13h <- as.factor(sub("  16 h", "", meteo$Desc_13h))
meteo$Desc_16h <- as.factor(meteo$Desc_16h)
meteo$Desc_10h[meteo$Desc_10h == "-"] <- "Pas d'obs"
meteo <- droplevels(meteo)
meteo <- meteo[as.Date(meteo$DATE) < "2019-12-01",]

temp <- strsplit(meteo$meteo, split = " ")
temp <- data.frame(matrix(unlist(temp), nrow=length(temp), byrow=T))
meteo$Temp.max <- as.numeric(sub("°C", "", temp[,14]))
meteo$Precipitation <- as.numeric(sub("mm", "", temp[,26]))
meteo$Ensoleillement <- as.numeric(sub("h", "", temp[,21]))

meteo$meteo <- NULL
rm(temp, i)

#save(meteo, file = "C:/Users/joach/OneDrive/Bureau/Visites Villandry/Donnees meteo Tours.Rda")
#load("C:/Users/joach/OneDrive/Bureau/Visites Villandry/Donnees meteo Tours.Rda")


##### Filling some of the blancs with historique-meteo.net  :

# At this step, we have about 25% of "No observation" values for the weather description variables. 
# We are going to fill thoses blancs with historique-meteo.net. Unfortunately, this site only offers 
# data from 2009 and weather description a 1pm. We have not found other sources to obtain this data for free. 

meteo$meteo <- ""
meteo$verif <- ""

for (year in 2009:2019){
  print(year)
  for (month in c("01","02","03","04","05","06","07","08","09","10","11","12")){
    print(month)
    for (day in 1:31){
      if(sum(year(meteo$DATE)==year & month(meteo$DATE)==as.numeric(month) & day(meteo$DATE)==day) == 1){
        meteo$verif[year(meteo$DATE)==year & month(meteo$DATE)==as.numeric(month) & day(meteo$DATE)==day] <- paste(as.character(year),"-", as.character(month), "-", as.character(day), sep = "")
        url <- paste("https://www.historique-meteo.net/france/centre/tours/", as.character(year),"/", month, "/", as.character(day), sep = "")
        meteo$meteo[year(meteo$DATE)==year & month(meteo$DATE)==as.numeric(month) & day(meteo$DATE)==day] <- html_text(html_node(read_html(url), xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "meteo_13h", " " ))]'))
      }
    }
  }
}

#save(meteo, file = "C:/Users/joach/OneDrive/Bureau/Visites Villandry/Donnees meteo Tours_completees.Rda")
#load("C:/Users/joach/OneDrive/Bureau/Visites Villandry/Donnees meteo Tours_completees.Rda")


##### Uniformisation of labels for the descriptions of the weather :

# We now have non-uniform labels because of the double sources of the data. We will bring together 
# the labels that are very close. 

# First, from the data of Météo France, we reduce the number of labels : 
# (some of them are extremely rare and therefore  not very usable) 
meteo$Desc_10h <- as.character(meteo$Desc_10h)
meteo$Desc_13h <- as.character(meteo$Desc_13h)
meteo$Desc_16h <- as.character(meteo$Desc_16h)

#Reunion of the mists
meteo$Desc_10h[meteo$Desc_10h %in% c("Bancs de brouillard", "Brouillard givrant")] <- "Brouillard"
meteo$Desc_13h[meteo$Desc_13h %in% c("Bancs de brouillard", "Brouillard givrant")] <- "Brouillard"
meteo$Desc_16h[meteo$Desc_16h %in% c("Bancs de brouillard", "Brouillard givrant")] <- "Brouillard"
#Reunion of the snows
meteo$Desc_10h[meteo$Desc_10h %in% c("Neige forte", "Quelques flocons")] <- "Neige"
meteo$Desc_13h[meteo$Desc_13h %in% c("Neige forte", "Quelques flocons")] <- "Neige"
meteo$Desc_16h[meteo$Desc_16h %in% c("Neige forte", "Quelques flocons")] <- "Neige"
#Reunion of rains
meteo$Desc_10h[meteo$Desc_10h %in% c("Pluie et neige", "Pluie forte", "Pluie verglaçante", "Pluies éparses")] <- "Pluies"
meteo$Desc_13h[meteo$Desc_13h %in% c("Pluie et neige", "Pluie forte", "Pluie verglaçante", "Pluies éparses")] <- "Pluies"
meteo$Desc_16h[meteo$Desc_16h %in% c("Pluie et neige", "Pluie forte", "Pluie verglaçante", "Pluies éparses")] <- "Pluies"
#Reunion of hail and thunderstorms
meteo$Desc_10h[meteo$Desc_10h == "Risque de grêle"] <- "Risque d'orages"
meteo$Desc_13h[meteo$Desc_13h == "Risque de grêle"] <- "Risque d'orages"
meteo$Desc_16h[meteo$Desc_16h == "Risque de grêle"] <- "Risque d'orages"
#Reunion of light rains
meteo$Desc_10h[meteo$Desc_10h %in% c("Rares averses", "Bruine")] <- "Pluie faible ou averses"
meteo$Desc_13h[meteo$Desc_13h %in% c("Rares averses", "Bruine")] <- "Pluie faible ou averses"
meteo$Desc_16h[meteo$Desc_16h %in% c("Rares averses", "Bruine")] <- "Pluie faible ou averses"

meteo <- droplevels(meteo)

meteo$verif <- NULL

# Incorporation of the historique-meteo.net's data :
temp <- strsplit(meteo$meteo[6576:10561], split = "\n")
temp <- as.character(data.frame(matrix(unlist(temp), nrow=length(temp), byrow=T))[,4])
meteo$meteo[6576:10561] <- temp

meteo$Desc_13h[meteo$Desc_13h == "Pas d'obs" & meteo$meteo != ""] <- meteo$meteo[meteo$Desc_13h == "Pas d'obs" & meteo$meteo != ""]


# Uniformisation of labels between the two sources :
meteo$Desc_13h[meteo$Desc_13h %in% c("Faibles averses de pluie", "Faibles averses de neige fondue", "Faible pluie non continue", "Faible pluie en continue", "Bruine légère partielle", "Bruine légère", "Pluie légère et soleil")] <- "Pluie faible ou averses"
meteo$Desc_13h[meteo$Desc_13h %in% c("Soleil et partiellement nuageux")] <- "Eclaircies"
meteo$Desc_13h[meteo$Desc_13h %in% c("Ciel dégagé, pleinement ensoleillé")] <- "Ensoleillé"
meteo$Desc_13h[meteo$Desc_13h %in% c("Faibles chutes de neige en continue")] <- "Neige"
meteo$Desc_13h[meteo$Desc_13h %in% c("Pluie modérée non continue", "Pluie modérée en continue", "Pluie forte ou modéré")] <- "Pluies"
meteo$Desc_13h[meteo$Desc_13h %in% c("Foyers orageux à proximité", "Averses de pluie et orages")] <- "Risque d'orages"
meteo$Desc_13h[meteo$Desc_13h %in% c("Nuageux", "Couvert")] <- "Très nuageux"

meteo$Desc_10h <- as.factor(meteo$Desc_10h)
meteo$Desc_13h <- as.factor(meteo$Desc_13h)
meteo$Desc_16h <- as.factor(meteo$Desc_16h)

meteo$meteo <- NULL

meteo$DATE <- as.Date(meteo$DATE)

# We will not use the shuneshine variables because Météo France does not offer forecasting for it.
meteo$Ensoleillement <- NULL

##### New variables to describe the overall weather of the day :

# 1) Weather's grade :
meteo$note_temps <- 0
note_temps <- data.frame(Desc_10h = levels(meteo$Desc_10h), note_1 = c( -1, 4, 5, -4, 0, -3, -5, -1, -1))
meteo <- left_join(meteo, note_temps, by = "Desc_10h") 
names(note_temps) <- c("Desc_13h", "note_2")
meteo <- left_join(meteo, note_temps, by = "Desc_13h") 
names(note_temps) <- c("Desc_16h", "note_3")
meteo <- left_join(meteo, note_temps, by = "Desc_16h") 
meteo$note_temps <- apply(meteo[8:10], 1, sum, na.rm = T)
meteo <- meteo[,1:7]

# 2) General description of the weather of the day :

# We set a description of the day for every combiaisons of weather descriptions at 10am, 1pm and 4pm.

temp <- levels(as.factor(paste(meteo$Desc_10h, meteo$Desc_13h, meteo$Desc_16h)))
temp <- data.frame(jour = temp, descr_generale = rep("", length(temp)))
temp$jour <- as.character(temp$jour)
temp$descr_generale <- as.character(temp$descr_generale)
temp$descr_generale[temp$jour %in% c("Brouillard Brouillard Brouillard", "Brouillard Brouillard Pas d'obs",
"Brouillard Brouillard Pluie faible ou averses",
"Brouillard Brouillard Très nuageux",
"Brouillard Pas d'obs Très nuageux",
"Brouillard Risque d'orages Très nuageux",
"Brouillard Très nuageux Brouillard",
"Brouillard Très nuageux Pas d'obs",
"Brouillard Très nuageux Très nuageux",
"Pluie faible ou averses Très nuageux Très nuageux",
"Pas d'obs Brouillard Très nuageux",
"Pas d'obs Risque d'orages Très nuageux",
"Pas d'obs Très nuageux Risque d'orages",
"Pas d'obs Très nuageux Très nuageux",
"Risque d'orages Très nuageux Très nuageux",
"Très nuageux Pas d'obs Risque d'orages",
"Pas d'obs Risque d'orages Pas d'obs",
"Pas d'obs Très nuageux Pas d'obs",
"Pas d'obs Pas d'obs Très nuageux",
"Très nuageux Pas d'obs Très nuageux",
"Très nuageux Pas d'obs Pas d'obs",
"Brouillard Pas d'obs Pas d'obs",
"Très nuageux Risque d'orages Pas d'obs",
"Très nuageux Risque d'orages Très nuageux",
"Très nuageux Très nuageux Pas d'obs",
"Très nuageux Très nuageux Risque d'orages",
"Très nuageux Très nuageux Très nuageux")] <- "Couvert"
temp$descr_generale[temp$jour %in% c("Brouillard Brouillard Eclaircies",
"Brouillard Brouillard Ensoleillé",
"Brouillard Eclaircies Brouillard",
"Brouillard Eclaircies Très nuageux",
"Brouillard Ensoleillé Très nuageux",
"Brouillard Pas d'obs Eclaircies",
"Brouillard Pas d'obs Ensoleillé",
"Brouillard Très nuageux Eclaircies",
"Brouillard Très nuageux Ensoleillé",
"Eclaircies Brouillard Brouillard",
"Eclaircies Brouillard Ensoleillé",
"Eclaircies Pluie faible ou averses Très nuageux",
"Eclaircies Eclaircies Risque d'orages",
"Eclaircies Eclaircies Très nuageux",
"Eclaircies Ensoleillé Très nuageux",
"Eclaircies Ensoleillé Très nuageux",
"Eclaircies Pas d'obs Risque d'orages",
"Eclaircies Pas d'obs Très nuageux",
"Eclaircies Risque d'orages Eclaircies",
"Eclaircies Risque d'orages Ensoleillé",
"Eclaircies Risque d'orages Pas d'obs",
"Eclaircies Risque d'orages Très nuageux",
"Eclaircies Très nuageux Eclaircies",
"Eclaircies Très nuageux Ensoleillé",
"Eclaircies Très nuageux Ensoleillé",
"Eclaircies Très nuageux Pas d'obs",
"Eclaircies Très nuageux Risque d'orages",
"Eclaircies Très nuageux Très nuageux",
"Ensoleillé Eclaircies Risque d'orages",
"Ensoleillé Eclaircies Très nuageux",
"Ensoleillé Ensoleillé Risque d'orages",
"Ensoleillé Ensoleillé Très nuageux",
"Ensoleillé Pas d'obs Très nuageux",
"Ensoleillé Très nuageux Eclaircies",
"Ensoleillé Très nuageux Ensoleillé",
"Ensoleillé Très nuageux Pas d'obs",
"Ensoleillé Très nuageux Très nuageux",
"Pas d'obs Eclaircies Très nuageux",
"Pas d'obs Ensoleillé Très nuageux",
"Pas d'obs Très nuageux Eclaircies",
"Pas d'obs Très nuageux Ensoleillé",
"Risque d'orages Eclaircies Eclaircies",
"Risque d'orages Eclaircies Très nuageux",
"Risque d'orages Pas d'obs Eclaircies",
"Risque d'orages Très nuageux Eclaircies",
"Très nuageux Eclaircies Eclaircies",
"Très nuageux Eclaircies Ensoleillé",
"Très nuageux Eclaircies Pas d'obs",
"Très nuageux Eclaircies Risque d'orages",
"Très nuageux Eclaircies Très nuageux",
"Très nuageux Ensoleillé Eclaircies",
"Très nuageux Ensoleillé Ensoleillé",
"Très nuageux Ensoleillé Pas d'obs",
"Très nuageux Ensoleillé Très nuageux",
"Très nuageux Pas d'obs Ensoleillé",
"Très nuageux Très nuageux Eclaircies",
"Très nuageux Très nuageux Ensoleillé",
"Très nuageux Pas d'obs Eclaircies")] <- "Couvert - Soleil"
temp$descr_generale[temp$jour %in% c("Brouillard Pluie faible ou averses Pluie faible ou averses",
"Brouillard Pluie faible ou averses Pas d'obs",
"Brouillard Pluie faible ou averses Très nuageux",
"Brouillard Pas d'obs Pluie faible ou averses",
"Brouillard Très nuageux Pluie faible ou averses",
"Pluie faible ou averses Brouillard Brouillard",
"Pluie faible ou averses Brouillard Pas d'obs",
"Pluie faible ou averses Brouillard Très nuageux",
"Pluie faible ou averses Brouillard Pas d'obs",
"Pluie faible ou averses Pluie faible ou averses Très nuageux",
"Pluie faible ou averses Pas d'obs Très nuageux",
"Pluie faible ou averses Pluie faible ou averses Très nuageux",
"Pluie faible ou averses Très nuageux Pluie faible ou averses",
"Pluie faible ou averses Très nuageux Pas d'obs",
"Pluie faible ou averses Très nuageux Pluies",
"Pluie faible ou averses Très nuageux Pluie faible ou averses",
"Pluie faible ou averses Très nuageux Risque d'orages",
"Neige Pluie faible ou averses Très nuageux",
"Pas d'obs Pluie faible ou averses Pluie faible ou averses",
"Pas d'obs Pluie faible ou averses Pluie faible ou averses",
"Pas d'obs Pluie faible ou averses Très nuageux",
"Pas d'obs Pluie faible ou averses Pluie faible ou averses",
"Pas d'obs Pluie faible ou averses Très nuageux",
"Pas d'obs Très nuageux Pluie faible ou averses",
"Pas d'obs Très nuageux Pluie faible ou averses",
"Pluie faible ou averses Pluie faible ou averses Pas d'obs",
"Pluie faible ou averses Pluie faible ou averses Très nuageux",
"Très nuageux Pluie faible ou averses Pluie faible ou averses",
"Très nuageux Pluie faible ou averses Pas d'obs",
"Très nuageux Pluie faible ou averses Pluie faible ou averses",
"Très nuageux Pluie faible ou averses Très nuageux",
"Très nuageux Pas d'obs Pluie faible ou averses",
"Pas d'obs Pluie faible ou averses Pas d'obs",
"Pas d'obs Pas d'obs Pluie faible ou averses",
"Très nuageux Pas d'obs Pluie faible ou averses",
"Très nuageux Pluie faible ou averses Pluie faible ou averses",
"Très nuageux Pluie faible ou averses Pas d'obs",
"Très nuageux Pluie faible ou averses Pluie faible ou averses",
"Très nuageux Risque d'orages Pluie faible ou averses",
"Pas d'obs Pluie faible ou averses Pas d'obs",
"Très nuageux Risque d'orages Pluie faible ou averses",
"Très nuageux Très nuageux Pluie faible ou averses",
"Pluie faible ou averses Pas d'obs Pas d'obs",
"Très nuageux Très nuageux Pluie faible ou averses",
"Très nuageux Pluie faible ou averses Très nuageux")] <- "Pluie légères"
temp$descr_generale[temp$jour %in% c("Brouillard Eclaircies Eclaircies",
"Brouillard Eclaircies Ensoleillé",
"Brouillard Eclaircies Pas d'obs",
"Brouillard Ensoleillé Eclaircies",
"Brouillard Ensoleillé Ensoleillé",
"Brouillard Ensoleillé Pas d'obs",
"Eclaircies Eclaircies Eclaircies",
"Eclaircies Eclaircies Ensoleillé",
"Eclaircies Eclaircies Pas d'obs",
"Eclaircies Ensoleillé Eclaircies",
"Eclaircies Ensoleillé Ensoleillé",
"Eclaircies Ensoleillé Pas d'obs",
"Eclaircies Pas d'obs Eclaircies",
"Eclaircies Pas d'obs Ensoleillé",
"Ensoleillé Eclaircies Eclaircies",
"Ensoleillé Eclaircies Ensoleillé",
"Ensoleillé Eclaircies Pas d'obs",
"Ensoleillé Ensoleillé Eclaircies",
"Ensoleillé Ensoleillé Ensoleillé",
"Ensoleillé Pas d'obs Pas d'obs",
"Ensoleillé Ensoleillé Pas d'obs",
"Ensoleillé Pas d'obs Eclaircies",
"Ensoleillé Pas d'obs Ensoleillé",
"Pas d'obs Eclaircies Eclaircies",
"Pas d'obs Eclaircies Ensoleillé",
"Pas d'obs Ensoleillé Eclaircies",
"Pas d'obs Ensoleillé Ensoleillé",
"Pas d'obs Pas d'obs Ensoleillé",
"Pas d'obs Ensoleillé Pas d'obs",
"Pluie faible ou averses Pas d'obs Très nuageux",
"Pluie faible ou averses Pluie faible ou averses Pluie faible ou averses",
"Pas d'obs Eclaircies Pas d'obs",
"Pas d'obs Pas d'obs Eclaircies",
"Eclaircies Pas d'obs Pas d'obs",
"Pluie faible ou averses Très nuageux Pluie faible ou averses",
"Pluie faible ou averses Très nuageux Pluie faible ou averses",
"Pluie faible ou averses Très nuageux Très nuageux")] <- "Soleil"
temp$descr_generale[temp$jour %in% c("Pas d'obs Pas d'obs Pas d'obs")] <- "Pas d'obs"
temp$descr_generale[temp$jour %in% c("Pluie faible ou averses Brouillard Eclaircies",
"Pluie faible ou averses Eclaircies Eclaircies",
"Pluie faible ou averses Eclaircies Ensoleillé ",
"Pluie faible ou averses Eclaircies Pas d'obs",
"Pluie faible ou averses Eclaircies Très nuageux",
"Pluie faible ou averses Ensoleillé Ensoleillé",
"Pluie faible ou averses Ensoleillé Pas d'obs",
"Pluie faible ou averses Pas d'obs Eclaircies",
"Pluie faible ou averses Pluie faible ou averses Eclaircies",
"Pluie faible ou averses Très nuageux Eclaircies",
"Pluie faible ou averses Très nuageux Ensoleillé",
"Eclaircies Pluie faible ou averses Eclaircies",
"Eclaircies Pluie faible ou averses Ensoleillé",
"Eclaircies Pluie faible ou averses Pas d'obs",
"Eclaircies Eclaircies Pluie faible ou averses",
"Eclaircies Eclaircies Neige",
"Eclaircies Eclaircies Pluie faible ou averses",
"Eclaircies Neige Très nuageux",
"Eclaircies Pas d'obs Pluie faible ou averses",
"Eclaircies Pluie faible ou averses Eclaircies",
"Eclaircies Pluie faible ou averses Pas d'obs",
"Eclaircies Pluie faible ou averses Pluie faible ou averses",
"Eclaircies Pluie faible ou averses Très nuageux",
"Eclaircies Risque d'orages Pluie faible ou averses",
"Eclaircies Très nuageux Pluie faible ou averses",
"Eclaircies Très nuageux Neige",
"Eclaircies Très nuageux Pluie faible ou averses",
"Ensoleillé Eclaircies Pluie faible ou averses",
"Ensoleillé Ensoleillé Neige",
"Ensoleillé Très nuageux Pluie faible ou averses",
"Neige Eclaircies Eclaircies",
"Neige Eclaircies Très nuageux",
"Neige Ensoleillé Ensoleillé",
"Neige Ensoleillé Pas d'obs",
"Pas d'obs Pluie faible ou averses Eclaircies",
"Pas d'obs Eclaircies Pluie faible ou averses",
"Pas d'obs Eclaircies Pluie faible ou averses",
"Pas d'obs Ensoleillé Pluie faible ou averses",
"Pas d'obs Pluie faible ou averses Eclaircies",
"Pluie faible ou averses Eclaircies Eclaircies",
"Pluie faible ou averses Eclaircies Pas d'obs",
"Pluie faible ou averses Eclaircies Très nuageux",
"Pluie faible ou averses Très nuageux Eclaircies",
"Très nuageux Pluie faible ou averses Eclaircies",
"Très nuageux Eclaircies Pluie faible ou averses",
"Très nuageux Eclaircies Pluie faible ou averses",
"Très nuageux Ensoleillé Pluie faible ou averses",
"Très nuageux Pluie faible ou averses Eclaircies")] <- "Pluies légères - Soleil"
temp$descr_generale[temp$jour %in% c("Eclaircies Très nuageux Pluies",
"Pluie faible ou averses Pluie faible ou averses Eclaircies",
"Eclaircies Pas d'obs Pluies",
"Eclaircies Pluies Eclaircies",
"Eclaircies Pluies Ensoleillé",
"Pluie faible ou averses Eclaircies Pluie faible ou averses",
"Eclaircies Pluies Pas d'obs",
"Eclaircies Pluies Pluies",
"Eclaircies Ensoleillé Pluies",
"Eclaircies Eclaircies Pluies",
"Eclaircies Pluies Très nuageux",
"Eclaircies Pluie faible ou averses Pluie faible ou averses",
"Eclaircies Pluies Pluie faible ou averses",
"Pluie faible ou averses Eclaircies Pluies",
"Pluie faible ou averses Pluies Eclaircies",
"Ensoleillé Eclaircies Pluies",
"Pas d'obs Eclaircies Pluies",
"Pluies Eclaircies Eclaircies",
"Pluies Eclaircies Pluie faible ou averses",
"Pluies Pas d'obs Eclaircies",
"Pluies Pluie faible ou averses Eclaircies",
"Pluies Très nuageux Eclaircies",
"Très nuageux Eclaircies Pluies",
"Très nuageux Pluies Eclaircies",
"Pas d'obs Pluies Eclaircies")] <- "Pluie - Soleil"
temp$descr_generale[temp$jour %in% c("Pluie faible ou averses Pluie faible ou averses Pluie faible ou averses",
"Pluie faible ou averses Pluie faible ou averses Neige",
"Pluie faible ou averses Pluie faible ou averses Pas d'obs",
"Pluie faible ou averses Pluie faible ou averses Pluies",
"Pluie faible ou averses Pluie faible ou averses Pluie faible ou averses",
"Pluie faible ou averses Pas d'obs Pluie faible ou averses",
"Pluie faible ou averses Pas d'obs Pluies",
"Pluie faible ou averses Pas d'obs Pluie faible ou averses",
"Pluie faible ou averses Pluies Pluie faible ou averses",
"Pluie faible ou averses Pluies Pas d'obs",
"Pluie faible ou averses Pluies Très nuageux",
"Pluie faible ou averses Pluie faible ou averses Pluie faible ou averses",
"Pluie faible ou averses Pluie faible ou averses Pas d'obs",
"Pluie faible ou averses Pluie faible ou averses Pluies",
"Pluie faible ou averses Pluie faible ou averses Pluie faible ou averses",
"Pas d'obs Pluie faible ou averses Pluies",
"Pluies Pluie faible ou averses Pas d'obs",
"Pluies Pluie faible ou averses Pluie faible ou averses",
"Pluies Pluies Très nuageux",
"Pluie faible ou averses Pas d'obs Pluies",
"Pluie faible ou averses Pluies Très nuageux",
"Risque d'orages Pluies Pluie faible ou averses",
"Pluies Pas d'obs Pas d'obs",
"Très nuageux Pluie faible ou averses Pluies",
"Très nuageux Pluies Pluie faible ou averses",
"Pas d'obs Pluies Pas d'obs")] <- "Pluie"
temp$descr_generale[temp$jour %in% c("Pluies Très nuageux Pas d'obs",
"Pluies Très nuageux Très nuageux",
"Pas d'obs Très nuageux Pluies",
"Très nuageux Pas d'obs Pluies",
"Très nuageux Pluies Pas d'obs",
"Très nuageux Pluies Risque d'orages",
"Très nuageux Pluies Très nuageux",
"Très nuageux Très nuageux Pluies",
"Pas d'obs Pluies Très nuageux")] <- "Pluie - Couvert"

meteo$jour <- paste(meteo$Desc_10h, meteo$Desc_13h, meteo$Desc_16h)
meteo <- left_join(meteo, temp, by = "jour")
meteo$jour <- NULL


# We fill the weather description at 1pm where there is "No observation" with the weather description at 4pm 
# in priority, and with the weather description at 10 am if needed. 
meteo$Desc_13h[meteo$Desc_13h == "Pas d'obs"] <- meteo$Desc_16h[meteo$Desc_13h == "Pas d'obs"]
meteo$Desc_13h[meteo$Desc_13h == "Pas d'obs"] <- meteo$Desc_10h[meteo$Desc_13h == "Pas d'obs"]

# Finaly, for the description of the weather at 1pm we have only 69 out of 11 561 "No observation" (0.65%)

# As usable variables we finaly have :
# - General description of the weather of the day 
# - Description of the weather at 1pm
# - Weather grade fo the day
# - Maximum temperature of the day
# - Precipitation

#save(meteo, file = "C:/Users/joach/OneDrive/Bureau/Visites Villandry/Donnees meteo Tours_Finales.Rda")

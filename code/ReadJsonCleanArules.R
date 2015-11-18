install.packages('arules')
install.packages('arulesViz')
install.packages('jsonlite')

library(ggplot2)
library(lubridate)
library(scales)
library(dplyr)
library(rpart)
library(arules)
library(arulesViz)
library(DBI)
library(RSQLite)
library(rjson)
library(jsonlite)

# connect to the sqlite file
setwd("/Users/tneureuther/ag-dank")
dir()
url <- 'parsed.jsonl'

#SQLite is ziemlich umständlich und langsam
#SQLite
#db <- dbConnect(SQLite(), dbname = "./db.sqlite")
#x <- dbGetQuery(db, "SELECT * from cars")

# JSON 
#document <- fromJSON(file=url, method='C')
#das ist leider nicht das format das wir haben wollen 
#head(document)
#str(document)

#jsonlite! ist die Lösung
require(jsonlite)
json_file <- stream_in(file(url))
head(json_file)
str(json_file)
dim(json_file)
#liste
typeof(json_file)

#---------------CLEAN-----------
#zeige character
summary(json_file$car1)
#binary to logical
#head(json_file$car1$Parkassistent)
#for(b in grep("car1.Parkassistent", colnames(json_file), value=TRUE)) json_file[[b]] <- as.logical(json_file[[b]])
#head(json_file$car1$Parkassistent)
#ist schon logisch xD

#-----------CLEAN-nominal into factors
head(json_file$car1$Motor)
summary(json_file$car1$Motor)
json_file$car1$Motor<- factor(json_file$car1$Motor, labels=c("Motor1", "Motor2", "Motor3",
                                                             "Motor4", "Motor5", "Motor6",
                                                             "Motor7", "Motor8", "Motor9"))
typeof(json_file$car1$Motor)
summary(json_file$car1)


#-----------CLEAN-character into factor oder so..
char <- sapply(json_file$car1, is.character)
char

head(json_file$car1$Line)
json_file$car1$Line <- lapply(json_file$car1$Line, as.integer)

head(json_file$car1$Raeder)
summary(json_file$car1$Farbe)
#Error sort.list?????? 
json_file$car1$Line <- as.factor(json_file$car1$Line)
json_file$car1$Raeder <- as.factor(json_file$car1$Raeder)
json_file$car1$Polster <- as.factor(json_file$car1$Polster)
json_file$car1$Leisten <- as.factor(json_file$car1$Leisten)
json_file$car1$Farbe <- as.factor(json_file$car1$Farbe)

summary(json_file$car1)
dat <- json_file$car1
head(dat)
summary(dat)

#------------------Association Rules---------------
#in Transaktions
col <- as.list(colnames(dat)) 
typeof(col)
col[2] <- NULL
as.vector(colnames(dat))
#"Line",
d <- dat[, c("Motor","Farbe", "Raeder","Polster", 
             "Leisten","Parkassistent","Sitzheizung für Fahrer und Beifahrer",              
             "Klimaautomatik, 2 Zonen mit erweitertem Umfang","Alarmanlage",
             "Digital Radio DVB","Automatik Getriebe","Aktive Geschwindigkeitsregelung mit Stop & Go Funktion",                
             "Xenonlicht für Abblend- und Fernlicht inkl. Scheinwerferreinigungsanlage",
             "Glas-Schiebe-Hebedach, elektrisch","HiFi-System",
             "Handy-Vorbereitung mit Bluetooth-Schnittstelle incl. USB" ,
             "Geschwindigkeitsregelung mit Bremsfunktion (DCC), inkl. Multifunktion" ,  
             "Lordosenstütze für Fahrer und Beifahrer","Armauflage vorn, verstellbar für Fahrer",           
             "Navigationssystem Business","Lichtpaket Interieur","Adaptives Kurvenlicht inkl. Fernlichtassistent,",   
             "Sport-Lederlenkrad","Ablagenpaket","Allradsystem xDrive","Adaptives M Fahrwerk (VDC) mit Fahrzeugtieferlegung",      
             "Variable Sportlenkung","M Lederlenkrad","Vollelektrische Sitzverstellung mit Memoryfunktion für Fahrer",          
             "Sportsitze für Fahrer und Beifahrer","Anhängevorrichtung, vollelektrisch","Sonnenschutzrollo für Heckscheibe, elektrisch",     
             "Comfortpaket","Rückfahrkamera","Spurwechselwarnung","Verkehrzeichenerkennung","DVD-Wechsler","Spurverlassenswarnung",
             "Komfortzugang","Head Up Display (HUD)","Sportpaket")]
trans <- as(d, "transactions")
summary(trans)

#----------------APRIORI-----------------
# find association rules with default settingsrules <- apriori()
itemsets <- apriori(trans, parameter = list(target = "frequent",
                                            supp=0.001, conf=0.8, minlen = 2, maxlen=4))
itemsets.sorted <- head(sort(itemsets), n=10)
plot(itemsets.sorted)
inspect(head(sort(itemsets), n=10))
plot(itemsets.sorted, method="graph", control=list(type="items"))
plot(itemsets.sorted, method="paracoord", control=list(reorder=TRUE))

rules <- apriori(trans, parameter = list(target = "frequent",
                                         supp=0.001, minlen = 2, maxlen=4))
inspect(rules)

rules <- apriori(trans, parameter = list(minlen=2, supp=0.04, conf=0.8))
rules.sorted <- sort(rules, by="lift")
inspect(rules.sorted)

#---PLOT RULES
plot(rules)
plot(rules, method="graph", control=list(type="items"))
plot(rules, method="paracoord", control=list(reorder=TRUE))

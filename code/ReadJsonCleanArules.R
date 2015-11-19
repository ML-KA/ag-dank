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
library(rjson)
library(jsonlite)

dir()
setwd("/Users/tneureuther/ag-dank/code")
dir.create(output)


#jsonlite! ist die Lösung
url <- 'code/parsed.jsonl'
require(jsonlite)
json_file <- stream_in(file(url))
head(json_file)
str(json_file)
dim(json_file)
#liste
typeof(json_file)

#---------------CLEAN-----------


#-----------CLEAN-nominal into factors
#head(json_file$car1$Motor)
#summary(json_file$car1$Motor)
json_file$car1$Motor<- factor(json_file$car1$Motor, labels=c("Motor1", "Motor2", "Motor3",
                                                             "Motor4", "Motor5", "Motor6",
                                                             "Motor7", "Motor8", "Motor9"))
json_file$car2$Motor<- factor(json_file$car1$Motor, labels=c("Motor1", "Motor2", "Motor3",
                                                             "Motor4", "Motor5", "Motor6",
                                                             "Motor7", "Motor8", "Motor9"))
typeof(json_file$car1$Motor)
summary(json_file$car1$Motor)


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
#car2
json_file$car2$Line <- as.factor(json_file$car2$Line)
json_file$car2$Raeder <- as.factor(json_file$car2$Raeder)
json_file$car2$Polster <- as.factor(json_file$car2$Polster)
json_file$car2$Leisten <- as.factor(json_file$car2$Leisten)
json_file$car2$Farbe <- as.factor(json_file$car2$Farbe)

#summary(json_file$car1)
dat1 <- json_file$car1
dat2 <- json_file$car2
typeof(dat1)
dat <- mapply(c, dat1, dat1, SIMPLIFY=FALSE)
?append
dat <- Map(c, dat1, dat2)
dat <- append(dat1, dat2) 
dat <- merge.list(dat1, dat2)
dat <- dat1
summary(dat2)
save(dat, file="car_clean.rda")
head(dat)


pdf(file="Datenhäufigkeit.pdf", width=25)
barplot(table(dat$Raeder), ylab="Number Raeder", las=3)
barplot(table(dat$Polster), ylab="Number Polster", las=3)
barplot(table(dat$Leisten), ylab="Number Leisten", las=3)
barplot(table(dat$Farbe), ylab="Number Farbe", las=3)
barplot(table(dat$'Farbe'), ylab="Number Farbe", las=3)
barplot(table(dat$Motor), ylab="Number Motor", las=3)
dev.off()


pairs(x = dat, 
      panel = panel.smooth,
      main = 'MTCars Attributes')
pairs(dat)

#---test
tbl <- table(dat$Leisten)
names(tbl) <- abbreviate(names(tbl), 8)
barplot(tbl, ylab="Leisten", las=3)

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
head(d)
trans <- as(d, "transactions")
summary(trans)

#----------------APRIORI-----------------
# find association rules with default settingsrules <- apriori()

itemFrequencyPlot(trans, topN=5,  cex.names=.5)

itemsets <- apriori(trans, parameter = list(target = "frequent", supp=0.005, minlen = 2, maxlen=4))
itemsets.sorted <- head(sort(itemsets), n=10)
inspect(head(sort(itemsets), n=10))

png(filename="itemset.png")
plot(itemsets.sorted)
dev.off() 

inspect(head(sort(itemsets)),n=10)
plot(itemsets.sorted, method="graph", control=list(type="items"))
plot(itemsets.sorted, method="paracoord", control=list(reorder=TRUE))


#apriori
rules <- apriori(trans, parameter = list(target = "frequent",
                                         supp=0.002, minlen = 2, maxlen=4))
inspect(rules, n= 10)



rules <- apriori(trans, parameter = list(minlen=2, supp=0.06, conf=0.8))
rules.sorted <- sort(rules, by="lift")
inspect(head(rules.sorted,10))
rules.sorted <- sort(rules, by="support")
inspect(head(rules.sorted,10))

?inspect
#---PLOT RULES
png(filename="apriori.png")
plot(rules.sorted)
dev.off()

plot(rules.sorted, method="graph", control=list(type="items"))

plot(rules.sorted, method="paracoord", control=list(reorder=TRUE))

plot(rules.sorted, method="doubledecker", data = Groceries)
plot(head(sort(rules, by="support"), 50),
     method="graph", control=list(cex=.7))
saveAsGraph(rules, "rules.graphml")

r_summon <- subset(rules, subset = items %pin% "sumissue")


#----Similarity
d <- dissimilarity(sample(trans, 50000), method = "phi", which = "items")
d[is.na(d)] <- 1 # get rid of missing values

pdf(file="similarity.pdf", width=25)
plot(hclust(d), cex=.5)
dev.off()

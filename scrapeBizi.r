require(rvest)
require(dplyr)
library(RSelenium)
require(XML)

html <- read_html("http://www.bizi.si/TSMEDIA/")
dejavnosti <- html_nodes(html, "#ctl00_cphMain_divActList a")

# stevilo dejavnosti
length(dejavnosti)

# imena dejavnosti 
html_text(dejavnosti)

# linki do dejavnosti
linki <- dejavnosti %>% html_attr("href")


izbran_html <- read_html(linki[1])
podjetja <- html_nodes(izbran_html, "th")

izbran_html %>% html_nodes(".gray , #ctl00_cphMain_DisplayRecords1_RepeaterResults_ctl01_lb_5259631000_linkCompany span") %>% html_attr("href")
podjetja %>% html_text

izbran_html %>%
  html_nodes("#divResults") %>%
  html_table() %>% .[[1]] %>% .[2:9] %>% as.tbl %>% .[-c(4,8),]

hop <- 
  read_html("http://www.bizi.si/TSMEDIA/A/avtobusni-prevozi-386/") %>%
  html_nodes("#divResults") %>%
  html_table()


# to je kul koda -> navedemo ime bowserja chrome, ker sem zloadal chromedrive.exe, ki se nahaja na C:\Users\Blaz\Documents
startServer()
remDr <- remoteDriver(browserName="chrome")
remDr$open()

urlBizi <- "http://www.bizi.si/TSMEDIA/A/avtobusni-prevozi-386/"
urlBizi <- "http://www.bizi.si/TSMEDIA/K/kampi-7228/"

remDr$navigate(urlBizi)
#setwd("C:/Users/Blaz/Documents")
#tabelaSkupna <- tabela %>%  dplyr::filter(Naziv=="00000")
#saveRDS(tabelaSkupna, file="tabelaSkupna.RDS")
#tabelaSkupna <- readRDS("tabelaSkupna.RDS") %>% mutate(`Matična številka` = as.character(`Matična številka`))

tabelaSkupna <- read_html(urlBizi) %>%
  html_nodes("#divResults") %>%
  html_table() %>% .[[1]] %>% .[2:9] %>% as.tbl %>% .[-c(4,8),] %>% mutate_each(funs(as.character))

# to nam pove koliko podstrani je. Premisli: kaj pa če jih je manj (naredi neko funkcijo, ki bo preverila)
zadnji <- c()
for (i in 1:5){
  zadnjaPodstran <- html_nodes(urlBizi %>% read_html, paste0("#ctl00_cphMain_ResultsPager_repPager_ctl0",i,"_btnPage")) %>%  html_text() 
  zadnji <- c(zadnji, zadnjaPodstran)
}
# tu pogledamo katera je zadnja stran, da vemo do kam moramo it
zadnjaPodstran <- max(zadnji %>%  as.numeric, na.rm=TRUE)

# eno funkcijo napisi, max gre do 5, najmanj je pa ena, naj se sprehodi med 1 in 5 in poglejda, če obstaja max,



if (zadnjaPodstran == 4)
  x <- c(2,4,5)
if (zadnjaPodstran == 3)
  x <- c(2,4)
if (zadnjaPodstran == 2)
  x <- 2
if (zadnjaPodstran >=5)
  x <- c(2,4,5,6, rep(7,zadnjaPodstran-5))


korak <- 1
for (i in x){
  korak <- korak+1
  webElem <- remDr$findElement(using = 'css', paste0("#ctl00_cphMain_ResultsPager_repPager_ctl0",i,"_btnPage"))
  Sys.sleep(5) # naj R malo zadrema, da se stran naloži
  webElem$sendKeysToElement(list(urlBizi, key = "enter"))
  
  page_source <- remDr$getPageSource()
  #print(i)
  
  
  tabela <- 
    read_html(page_source[[1]]) %>%
    html_nodes("#divResults") %>%
    html_table() %>% .[[1]] %>% .[2:9] %>% as.tbl  %>%
      mutate_each(funs(as.character))
print(tabela)  
  tabelaSkupna <- bind_rows(tabelaSkupna,tabela)
  print(paste0("Končal s korakom št. ",korak," od ", zadnjaPodstran, "."))
}


# saveRDS(tabelaSkupna, file="tabelaSkupna.RDS")
tabelaSkupna <- readRDS("tabelaSkupna.RDS")

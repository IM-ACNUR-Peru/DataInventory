library(readxl)
library(utils)
library(shiny)
library(bslib)
library(DT)
library(palmerpenguins)
library(dplyr)

df <- read.csv("https://github.com/IM-ACNUR-Peru/DataInventory/raw/refs/heads/main/DataInventory.csv", fileEncoding="latin1") |>
  select(`Área.Temática`:Comentario)

fecha <- Sys.Date()

ui <- page_fluid(
  tags$head(
    tags$style(HTML("
      table.dataTable td {
        font-size: 12px;
        font-family: 'Lato', sans-serif;
        color: #333;
      }
      table.dataTable th {
        font-size: 13px;
        font-weight: bold;
        color: #2C3E50;
      }
    "))
  ),

  style = "background-color: #CCE3F2; padding: 20px; text-align: center;",

  tags$div(
    style = "
    width: 100%;
    background-color: #0072BC;
    padding: 20px 0;
    text-align: center;
  ",
    tags$h2("Data Inventory", style = "color: white; margin: 0;"),
    tags$h4("ACNUR Perú", style = "color: white;")
  ),
#  tags$h2("Data Inventory ACNUR Perú", style = "color: #0072BC;"),
#  tags$h4(fecha, style = "color: #338EC9;"),
  br(),
  dataTableOutput("table")
)


server <- function(input, output) {
  output$table <- renderDT({
    datatable(
      df,
      extensions = 'Buttons',
      options = list(
        dom = 'Bfrtip',
        pageLength = 50,
        buttons = list(
          list(
            extend = 'csv',
            filename = JS("function() { return 'DataInventory_ACNURPeru_' + new Date().toISOString().slice(0,10); }"),
            title = 'Data Inventory - ACNUR Perú'
          ),
          list(
            extend = 'pdf',
            filename = JS("function() { return 'DataInventory_ACNURPeru_' + new Date().toISOString().slice(0,10); }"),
            title = 'Data Inventory - ACNUR Perú',
            customize = JS("
              function(doc) {
                var now = new Date();
                var dateStr = now.toLocaleDateString();
                doc.content.push({
                  text: 'Creado el: ' + dateStr,
                  margin: [0, 30, 0, 0],
                  alignment: 'center',
                  fontSize: 10
                });
              }
            ")
          ),
          list(
            extend = 'print',
            title = 'Data Inventory - ACNUR Perú',
            customize = JS("
              function(win) {
                var now = new Date();
                var dateStr = now.toLocaleDateString();
                $(win.document.body).append(
                  '<div style=\"text-align:center; margin-top:20px; font-size:10pt;\">Downloaded on: ' + dateStr + '</div>'
                );
              }
            ")
          )
        )
      ),
      filter = 'top'
    )
  }, server = FALSE)
}


shinyApp(ui = ui, server = server)


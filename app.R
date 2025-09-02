library(readxl)
library(utils)
library(shiny)
library(bslib)
library(DT)
library(dplyr)
library(stringr)
library(shinyWidgets)

df <- read.csv("https://github.com/IM-ACNUR-Peru/DataInventory/raw/refs/heads/main/DataInventory.csv", fileEncoding="latin1") |>
#df <- read.csv("DataInventory.csv", fileEncoding="latin1") |>
 select(`Área.Temática`:Status) |>
  mutate(Valor = str_remove_all(Valor, ",")) |>
  mutate(Valor = as.numeric(Valor)) |>
  mutate(Valor = if_else(Valor <= 1, paste0(Valor * 100, "%"), format(round(Valor, 0), big.mark=",")))

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

/* Three-column layout: dropdown | buttons | search */
      .filter-and-buttons-container {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 10px;
        min-height: 40px;
      }

      .filter-section {
        flex: 0 0 auto;
        min-width: 200px;
      }

      .buttons-section {
        flex: 0 0 auto;
        display: flex;
        justify-content: center;
      }

      .search-section {
        flex: 0 0 auto;
        min-width: 200px;
        display: flex;
        justify-content: flex-end;
      }

      /* Ensure DataTable buttons container aligns properly */
      .dataTables_wrapper .dt-buttons {
        margin-bottom: 0.5em;
      }

      /* Hide the default DataTable search box */
      .dataTables_wrapper .dataTables_filter {
        display: none;
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


# Combined container for filter and space for buttons
  tags$div(
    class = "filter-and-buttons-container",
    tags$div(
      class = "filter-section",
      pickerInput(
        inputId = "status_filter",
        label = NULL,
        choices = c("Key data", "Otros datos recientes", "Datos históricos"),
        selected = "Key data",
        multiple = TRUE,
        options = list(
          style = "btn-primary",
          `selected-text-format` = "count > 2",
          `actions-box` = TRUE
        )
      )
    ),
    # Placeholder div for DataTable buttons (center)
    tags$div(class = "buttons-section", id = "buttons-placeholder"),
    # Custom search box (right)
    tags$div(
      class = "search-section",
      tags$input(
        type = "text",
        id = "custom-search",
        placeholder = "Search...",
        class = "form-control",
        style = "width: 200px;"
      )
    )
  ),


  DTOutput("table"),

  # JavaScript to move DataTable buttons and connect custom search
  tags$script(HTML("
    $(document).on('init.dt', function(e, settings) {
      // Move the DataTable buttons to our custom container
      setTimeout(function() {
        var buttonsContainer = $('.dt-buttons').detach();
        $('#buttons-placeholder').append(buttonsContainer);

        // Connect custom search box to DataTable
        $('#custom-search').on('keyup', function() {
          $('#table').DataTable().search(this.value).draw();
        });

        // Clean up the original buttons wrapper if it's empty
        $('.dataTables_wrapper .dataTables_length').parent().find('.dt-buttons').parent().remove();
      }, 100);
    });
    "))

)


server <- function(input, output) {
  output$table <- renderDT({

    dt_filtered <- df  |>
      filter(Status %in% input$status_filter)  |>
      select(-Status)  # Remove Status column from display

    datatable(
      dt_filtered,
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
                doc.defaultStyle.fontSize = 8;
                doc.styles.tableHeader.fontSize = 9;
                var now = new Date();
                var dateStr = now.toLocaleDateString();
                doc.content.push({
                  text: 'Creado el: ' + dateStr,
                  margin: [0, 30, 0, 0],
                  alignment: 'center',
                  fontSize: 8
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


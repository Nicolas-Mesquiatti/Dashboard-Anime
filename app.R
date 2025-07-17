library(shiny)
library(ggplot2)
library(dplyr)
library(DT)
library(forcats)
library(scales)
library(ggthemes)
library(plotly)
library(shinythemes)
library(RColorBrewer)
library(shinyjs)
library(wordcloud)
library(tm)


# Cargar datos
anime_data <- read.csv("Anime.csv")

# Preprocesamiento
anime_data <- anime_data %>%
  mutate(
    type = as.factor(type),
    rated = as.factor(ifelse(rated == "", "No clasificado", as.character(rated))),
    airing = as.factor(ifelse(airing, "Sí", "No")),
    popularity = cut(members,
                     breaks = quantile(members, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE),
                     labels = c("Baja", "Media", "Alta", "Muy Alta"),
                     include.lowest = TRUE),
    # Crear categoría de duración basada en episodios
    duration_category = case_when(
      episodes == 1 ~ "Película/Especial",
      episodes > 1 & episodes <= 12 ~ "Corta (1-12 eps)",
      episodes > 12 & episodes <= 24 ~ "Media (13-24 eps)",
      episodes > 24 & episodes <= 50 ~ "Larga (25-50 eps)",
      episodes > 50 ~ "Muy larga (+50 eps)",
      TRUE ~ "Desconocido"
    )
  )

# Paletas de colores
anime_palettes <- list(
  "Naruto" = list(
    fill = c("#FF9900", "#0066CC", "#FFFFFF", "#663300", "#000000", 
             "#FFCC33", "#3399FF", "#996633", "#CC9966", "#003399"),
    background = "#000000",
    navbar = "#FF9900",
    sidebar = "#FFE0B2",
    header_img = "https://pressakey.com/gamepix/8202/Naruto-X-Boruto-Ultimate-Ninja-Storm-Connections-281010.jpg",
    header_height = "170px",
    wordcloud_bg = "#FFF4E0"
  ),
  "Dragon Ball" = list(
    fill = c("#FFCC00", "#FF6600", "#3366CC", "#FF3300", "#003366",
             "#FF9933", "#66CCFF", "#990000", "#CC6600", "#0066CC"),
    background = "#FF6600",
    navbar = "#990000",
    sidebar = "#FFD699",
    header_img = "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/0ac38adc-f48d-4177-b61d-01e4905b539f/dh113sn-24845383-1e82-4fff-bfa0-a9798b73eebd.jpg/v1/fill/w_1280,h_718,q_75,strp/dragon_ball___anime_wallpaper_4k_by_vowebox_dh113sn-fullview.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7ImhlaWdodCI6Ijw9NzE4IiwicGF0aCI6IlwvZlwvMGFjMzhhZGMtZjQ4ZC00MTc3LWI2MWQtMDFlNDkwNWI1MzlmXC9kaDExM3NuLTI0ODQ1MzgzLTFlODItNGZmZi1iZmEwLWE5Nzk4YjczZWViZC5qcGciLCJ3aWR0aCI6Ijw9MTI4MCJ9XV0sImF1ZCI6WyJ1cm46c2VydmljZTppbWFnZS5vcGVyYXRpb25zIl19.njwO4Ht2utORaMyUUxytST6uHoN-49DSXBt7aGBNZJ8",
    header_height = "280px",
    header_position = "left 85%",
    wordcloud_bg = "#FFF0D9"
  ),
  "One Piece" = list(
    fill = c("#CC0000", "#0000CC", "#FFFF00", "#990000", "#000099",
             "#FF3333", "#3333FF", "#FF9900", "#660000", "#000066"),
    background = "#FFE6E6",
    navbar = "#CC0000",
    sidebar = "#FFCCCC",
    header_img = "https://e0.pxfuel.com/wallpapers/264/440/desktop-wallpaper-of-one-piece-manga-black-and-white-fo-luffy-black-and-white.jpg",
    header_height = "270px",
    wordcloud_bg = "#FFE6E6"
  ),
  "Bleach" = list(
    fill = c("#000000", "#FF4500", "#1E90FF", "#FFFFFF", "#8B0000",
             "#4682B4", "#B22222", "#696969", "#4169E1", "#DC143C"),
    background = "#E6E6FA",
    navbar = "#000000",
    sidebar = "#D3D3D3",
    header_img = "https://cms.rhinoshield.app/public/images/BLEACH_collectio_banner_Mobile_1413105901.png",
    header_height = "160px",
    wordcloud_bg = "#E6E6FA"
  ),
  "Attack on Titan" = list(
    fill = c("#2F4F4F", "#8B0000", "#708090", "#A9A9A9", "#556B2F",
             "#B8860B", "#696969", "#800000", "#2E8B57", "#483D8B"),
    background = "#F5F5F5",
    navbar = "#8B0000",
    sidebar = "#DCDCDC",
    header_img = "https://wallpapercave.com/wp/wp1837568.jpg",
    header_height = "390px",
    wordcloud_bg = "#F5F5F5"
  ),
  "Predeterminado" = list(
    fill = viridis::viridis_pal()(10),
    background = "#f8f9fa",
    navbar = "#2c3e50",
    sidebar = "#ecf0f1",
    header_img = "https://images.hdqwalls.com/wallpapers/saiyan-warrior-ultimate-form-5f.jpg",
    header_height = "200px",
    wordcloud_bg = "#f8f9fa"
  )
)

# Interfaz de usuario
ui <- fluidPage(
  useShinyjs(),
  theme = shinytheme("flatly"),
  
  tags$head(
    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Bangers&display=swap"),
    tags$style(HTML("
      body {
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        transition: background-color 0.5s;
      }
      .irs-bar,
      .irs-bar-edge,
      .irs-single,
      .irs-line {
        background-color: #FFB74D !important;
        border-color: #FFA726 !important;
      }
      .irs-from, .irs-to, .irs-single {
        background-color: #FF9800 !important;
        border-color: #EF6C00 !important;
        color: white !important;
      }
      .irs-handle {
        border: 2px solid #F57C00 !important;
        background: #FF9800 !important;
        width: 16px;
        height: 16px;
        top: 22px;
      }
      .irs-line {
        background: #FFE0B2 !important;
        border: 1px solid #FFCC80 !important;
      }
      .navbar {
        border: none;
      }
      .navbar-brand {
        color: white !important;
        font-weight: bold;
        font-size: 24px;
      }
      .sidebar {
        border-radius: 12px;
        padding: 20px;
        box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        transition: background-color 0.5s;
      }
      .sidebar label {
        font-weight: bold;
        color: #6E2C00;
        margin-top: 10px;
        display: block;
      }
      .sidebar select,
      .sidebar input[type='text'],
      .sidebar input[type='number'],
      .sidebar input[type='range'],
      .sidebar .form-control {
        background-color: #FFF4E0;
        border: 2px solid #FFA726;
        border-radius: 8px;
        padding: 6px;
        color: #4E342E;
      }
      .nav-tabs > li.active > a {
  background-color: #FF5722 !important;
  color: white !important;
  border-bottom: 3px solid #E91E63;
}
      .sidebar .checkbox label {
        color: #4E342E;
        font-weight: normal;
      }
      .btn-primary {
        background-color: #FF9800;
        border-color: #FB8C00;
        color: white;
      }
      .btn-primary:hover {
        background-color: #F57C00;
        border-color: #EF6C00;
      }
      
.sidebar, .main-panel, .tab-content {
  transition: all 0.4s cubic-bezier(0.68, -0.55, 0.27, 1.55);
}

.plot-container:hover {
  transform: scale(1.02);
}
      .tab-content {
        background-color: #FFFFFF;
        border-radius: 8px;
        padding: 20px;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
      }
      h2, h1 {
        color: #BF360C;
        text-shadow: 1px 1px 0px #fff0e0;
      }
      table.dataTable {
        background-color: #FFFDE7;
      }
      table.dataTable th {
        background-color: #FFCC80;
        color: #4E342E;
      }
      table.dataTable td {
        background-color: #FFF8E1;
        color: #5D4037;
      }
      .plot-title {
        font-size: 20px;
        font-weight: bold;
        text-align: center;
        margin-bottom: 15px;
      }
      .plot-container {
        margin-bottom: 30px;
      }
      .wordcloud-container {
        height: 700px !important;
        width: 100% !important;
        margin-top: 20px;
      }
      .wordcloud-title {
        text-align: center;
        font-size: 24px;
        font-weight: bold;
        margin-bottom: 20px;
        color: #333;
      }
      .main-panel {
  border-radius: 15px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  box-shadow: 0 8px 32px rgba(31, 38, 135, 0.37);
  border: 1px solid rgba(255, 255, 255, 0.18);
  transition: all 0.4s cubic-bezier(0.68, -0.55, 0.27, 1.55);
}
      .body-bg {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        z-index: -1;
        opacity: 0.1;
        background-size: cover;
        background-position: center;
        background-repeat: no-repeat;
      }
      h1, h2 {
  font-family: 'Bangers', cursive;
  letter-spacing: 1px;
  text-transform: uppercase;
  background: linear-gradient(to right, #FF5722, #E91E63);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
      .scatter-plot-container {
        height: 600px !important;
      }
      .selected-animes-table {
        margin-top: 20px;
        background-color: white;
        border-radius: 8px;
        padding: 15px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      }
      .bleach-title {
        font-size: 60px;
        font-weight: bold;
      }
      /* Efecto hover para contenedores de gráficos */
.plot-container {
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  border-radius: 10px;
  padding: 15px;
}

.plot-container:hover {
  transform: translateY(-5px);
  box-shadow: 0 15px 30px rgba(0,0,0,0.15);
  z-index: 10;
}


.dataTables_wrapper {
  transition: all 0.3s ease;
  border-radius: 10px;
  overflow: hidden;
}

.dataTables_wrapper:hover {
  box-shadow: 0 10px 25px rgba(0,0,0,0.2);
}
    "))
  ),
  
  # Fondo de pantalla
  div(class = "body-bg", style = "background-image: url('https://images.unsplash.com/photo-1633613286848-e6f43bbafb8d?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80');"),
  
  titlePanel(
    uiOutput("dynamic_header")
  ),
  
  sidebarLayout(
    sidebarPanel(
      width = 2,
      class = "sidebar",
      selectInput("tipo", "Tipo de Anime:",
                  choices = c("Todos", levels(anime_data$type)),
                  selected = "Todos"),
      sliderInput("episodios", "Número de Episodios:",
                  min = 0, max = max(anime_data$episodes, na.rm = TRUE), 
                  value = c(0, max(anime_data$episodes, na.rm = TRUE))),
      sliderInput("puntuacion", "Rango de Puntuación:",
                  min = 0, max = 10, value = c(0, 10), 
                  step = 0.1),
      checkboxGroupInput("clasificacion", "Clasificación:",
                         choices = levels(anime_data$rated),
                         selected = unique(anime_data$rated)),
      sliderInput("top_n", "Número de Top Animes:",
                  min = 5, max = 40, value = 10),
      selectInput("tema_anime", "Tema de Anime:",
                  choices = c("Predeterminado", "Naruto", "Dragon Ball", 
                              "One Piece", "Bleach", "Attack on Titan"),
                  selected = "Predeterminado"),
      actionButton("reset", "Reiniciar Filtros", icon = icon("sync"),
                   class = "btn-primary btn-block")
    ),
    
    mainPanel(
      width = 9,
      class = "main-panel",
      tabsetPanel(
        tabPanel("Resumen General",
                 fluidRow(
                   column(6, 
                          div(class = "plot-container",
                              plotOutput("typeDistributionPlot", height = "400px")
                          )
                   ),
                   column(6, 
                          div(class = "plot-container",
                              plotOutput("durationCategoryPlot", height = "400px")
                          )
                   )
                 )
        ),
        
        tabPanel("Top Animes",
                 h3("Top Animes por Puntuación"),
                 div(class = "plot-container",
                     plotOutput("topScorePlot", height = "500px")
                 ),
                 h3("Top Animes por Popularidad"),
                 div(class = "plot-container",
                     plotOutput("topPopularityPlot", height = "500px")
                 ),
                 fluidRow(
                   column(12, 
                          div(class = "plot-container",
                              plotOutput("ratingComparisonPlot", height = "400px")
                          )
                   )
                 )
        ),
        tabPanel("Análisis Detallado",
                 fluidRow(
                   column(12,
                          div(class = "plot-container",
                              plotlyOutput("interactiveScatterPlot", height = "500px")
                          )
                   )
                 ),
                 fluidRow(
                   column(12,
                          h3("Detalles de Animes Seleccionados"),
                          div(class = "plot-container",
                              DTOutput("selectedAnimeDetails")
                          )
                   )
                 )
        ),
        tabPanel("Títulos y Palabras Clave",
                 div(class = "wordcloud-title", "Palabras Más Comunes en Títulos"),
                 div(class = "wordcloud-container plot-container",
                     plotOutput("titleWordcloudPlot", height = "600px")
                 ),
                 h3("Distribución de Tipos"),
                 div(class = "plot-container",
                     plotOutput("typeDistributionPlot2", height = "500px")
                 )
        ),
        tabPanel("Datos Completos",
                 div(class = "plot-container",
                     DTOutput("fullDataTable")
                 )
        )
      ) 
    )   
  )    
 ) 

# Servidor
server <- function(input, output, session) {
  session$onSessionEnded(stopApp)
  # Datos reactivos con filtros aplicados
  datos_filtrados <- reactive({
    data <- anime_data
    
    if(input$tipo != "Todos") {
      data <- data %>% filter(type == input$tipo)
    }
    
    data <- data %>%
      filter(
        episodes >= input$episodios[1],
        episodes <= input$episodios[2],
        score >= input$puntuacion[1],
        score <= input$puntuacion[2],
        rated %in% input$clasificacion
      )
    
    return(data)
  })
  
  # Reiniciar filtros
  observeEvent(input$reset, {
    updateSelectInput(session, "tipo", selected = "Todos")
    updateSliderInput(session, "episodios", 
                      value = c(0, max(anime_data$episodes, na.rm = TRUE)))
    updateSliderInput(session, "puntuacion", value = c(0, 10))
    updateCheckboxGroupInput(session, "clasificacion", 
                             selected = unique(anime_data$rated))
    updateSliderInput(session, "top_n", value = 10)
    updateSelectInput(session, "tema_anime", selected = "Predeterminado")
  })
  
  # Aplicar tema seleccionado
  observeEvent(input$tema_anime, {
    tema <- input$tema_anime
    paleta <- anime_palettes[[tema]]
    
    # Aplicar estilos
    runjs(sprintf("document.body.style.backgroundColor = '%s';", paleta$background))
    runjs(sprintf("document.querySelector('.navbar').style.backgroundColor = '%s';", paleta$navbar))
    runjs(sprintf("document.querySelector('.sidebar').style.backgroundColor = '%s';", paleta$sidebar))
    
    # Actualizar altura del encabezado
    runjs(sprintf("document.querySelector('.header-container').style.height = '%s';", paleta$header_height))
    
    # Actualizar fondo de pantalla
    runjs(sprintf("document.querySelector('.body-bg').style.backgroundImage = 'url(\"%s\")';", paleta$header_img))
  })
  
  # Encabezado dinámico
  output$dynamic_header <- renderUI({
    tema <- input$tema_anime
    paleta <- anime_palettes[[tema]]
    
    div(class = "header-container",
        style = sprintf(
          "background-image: url('%s');
           background-size: cover;
           background-position: center;
           color: white;
           padding: 100px;
           border-radius: 8px;
           text-align: center;
           height: %s;
           margin-bottom: 20px;",
          paleta$header_img,
          paleta$header_height
        ),
        if(tema == "Bleach") {
          div(
            span(style = "color: white; font-size: 60px; font-weight: bold;", "DASHBOARD"),
            span(style = "color: black; font-size: 60px; font-weight: bold;", " DE ANIMES")
          )
        } else {
          h1("Dashboard de Animes", 
             style = "margin: 10px; color:white; text-shadow:1px 1px 2px white; font-size: 60px;")
        }
    )
  })
  
  # Función para obtener paleta de colores
  get_palette <- reactive({
    tema <- input$tema_anime
    paleta <- anime_palettes[[tema]]$fill
    
    if(tema == "Predeterminado") {
      return(scale_fill_viridis_d(option = "viridis", end = 0.9))
    } else {
      return(scale_fill_manual(values = paleta))
    }
  })
  
  # Función para obtener paleta de colores (versión color)
  get_color_palette <- reactive({
    tema <- input$tema_anime
    paleta <- anime_palettes[[tema]]$fill
    
    if(tema == "Predeterminado") {
      return(scale_color_viridis_d(option = "viridis", end = 0.9))
    } else {
      return(scale_color_manual(values = paleta))
    }
  })
  
  # 1. Distribución por tipo de anime
  output$typeDistributionPlot <- renderPlot({
    df <- datos_filtrados()
    
    if(nrow(df) > 0) {
      type_counts <- df %>%
        count(type) %>%
        arrange(desc(n)) %>%
        mutate(type = fct_reorder(type, n))
      
      ggplot(type_counts, aes(x = type, y = n, fill = type)) +
        geom_col(show.legend = FALSE) +
        geom_text(aes(label = n), vjust = -0.5, size = 5, fontface = "bold") +
        get_palette() +
        labs(title = "Distribución por Tipo de Anime",
             x = "Tipo",
             y = "Cantidad") +
        theme_minimal(base_size = 14) +
        theme(
          plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
          axis.text.x = element_text(angle = 45, hjust = 1)
        )
    } else {
      ggplot() + 
        annotate("text", x = 1, y = 1, size = 6, 
                 label = "No hay datos con los filtros seleccionados") +
        theme_void()
    }
  })
  
  # 2. Distribución por categoría de duración
  output$durationCategoryPlot <- renderPlot({
    df <- datos_filtrados()
    
    if(nrow(df) > 0) {
      duration_counts <- df %>%
        count(duration_category) %>%
        mutate(duration_category = fct_reorder(duration_category, n))
      
      ggplot(duration_counts, aes(x = duration_category, y = n, fill = duration_category)) +
        geom_col(show.legend = FALSE) +
        geom_text(aes(label = n), vjust = -0.5, size = 5, fontface = "bold") +
        get_palette() +
        labs(title = "Distribución por Duración",
             x = "Categoría de Duración",
             y = "Cantidad") +
        theme_minimal(base_size = 14) +
        theme(
          plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
          axis.text.x = element_text(angle = 45, hjust = 1)
        )
    } else {
      ggplot() + 
        annotate("text", x = 1, y = 1, size = 6, 
                 label = "No hay datos con los filtros seleccionados") +
        theme_void()
    }
  })
  
  # 4. Top animes por puntuación
  output$topScorePlot <- renderPlot({
    df <- datos_filtrados()
    
    if(nrow(df) > 0) {
      top_n <- min(input$top_n, nrow(df))
      df_top <- df %>%
        arrange(desc(score)) %>%
        head(top_n)
      
      ggplot(df_top, aes(x = score, y = reorder(title, score), fill = type)) +
        geom_col(color = "black", width = 0.8, alpha = 0.99) +
        geom_text(aes(label = sprintf("%.2f", score)), 
                  hjust = 1.2, color = "white", size = 4, fontface = "bold") +
        get_palette() +
        labs(
          x = "Puntuación",
          y = "",
          fill = "Tipo"
        ) +
        theme_minimal(base_size = 14) +
        theme(
          legend.position = "bottom",
          plot.title = element_blank(),
          axis.text.y = element_text(size = 11),
          panel.grid.major.y = element_blank()
        )
    } else {
      ggplot() + 
        annotate("text", x = 1, y = 1, size = 6, 
                 label = "No hay datos con los filtros seleccionados") +
        theme_void()
    }
  })
  
  # 5. Top animes por popularidad (miembros)
  output$topPopularityPlot <- renderPlot({
    df <- datos_filtrados()
    
    if(nrow(df) > 0) {
      top_n <- min(input$top_n, nrow(df))
      df_top <- df %>%
        arrange(desc(members)) %>%
        head(top_n)
      
      ggplot(df_top, aes(x = members, y = reorder(title, members), fill = type)) +
        geom_col(color = "black", width = 0.8, alpha = 0.99) +
        geom_text(aes(label = format(members, big.mark = ",")), 
                  hjust = 1.1, color = "white", size = 4, fontface = "bold") +
        scale_x_continuous(labels = comma) +
        get_palette() +
        labs(
          x = "Miembros",
          y = "",
          fill = "Tipo"
        ) +
        theme_minimal(base_size = 14) +
        theme(
          legend.position = "bottom",
          plot.title = element_blank(),
          axis.text.y = element_text(size = 11),
          panel.grid.major.y = element_blank()
        )
    } else {
      ggplot() + 
        annotate("text", x = 1, y = 1, size = 6, 
                 label = "No hay datos con los filtros seleccionados") +
        theme_void()
    }
  })
  
  # 6. Comparación de puntuaciones por clasificación
  output$ratingComparisonPlot <- renderPlot({
    df <- datos_filtrados()
    
    if(nrow(df) > 0) {
      ggplot(df, aes(x = rated, y = score, fill = rated)) +
        geom_violin(alpha = 0.7) +
        geom_boxplot(width = 0.1, fill = "white", alpha = 0.5) +
        stat_summary(fun = mean, geom = "point", shape = 18, size = 4, color = "red") +
        get_palette() +
        labs(
          title = "Distribución de Puntuaciones por Clasificación",
          x = "Clasificación",
          y = "Puntuación"
        ) +
        theme_minimal(base_size = 14) +
        theme(
          legend.position = "none",
          plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
          axis.text.x = element_text(angle = 45, hjust = 1)
        )
    } else {
      ggplot() + 
        annotate("text", x = 1, y = 1, size = 6, 
                 label = "No hay datos con los filtros seleccionados") +
        theme_void()
    }
  })
  
  # Gráfico de dispersión interactivo
  output$interactiveScatterPlot <- renderPlotly({
    df <- datos_filtrados() %>%
      filter(!is.na(score), !is.na(members), !is.na(episodes))
    
    if(nrow(df) == 0) {
      return(plotly_empty() %>% 
               layout(title = "No hay datos disponibles con los filtros actuales"))
    }
    
    # Crear un ID único para cada anime
    df <- df %>% 
      mutate(id = row_number(),
             size = scales::rescale(episodes, to = c(5, 30)))
    
    p <- plot_ly(
      data = df,
      x = ~members,
      y = ~score,
      color = ~type,
      size = ~size,
      sizes = c(5, 30),
      text = ~paste(
        "<b>", title, "</b><br>",
        "Tipo: ", type, "<br>",
        "Puntuación: ", round(score, 2), "<br>",
        "Miembros: ", format(members, big.mark = ","), "<br>",
        "Episodios: ", episodes, "<br>",
        "Clasificación: ", rated
      ),
      hoverinfo = "text",
      customdata = ~id,  # Usar ID como referencia
      type = "scatter",
      mode = "markers",
      source = "anime_scatter",
      marker = list(
        line = list(width = 1, color = 'rgba(0, 0, 0, 0.5)'),
        opacity = 0.8
      )
    ) %>%
      layout(
        title = "Relación entre Popularidad, Puntuación y Duración",
        xaxis = list(title = "Miembros (Popularidad)", type = "log"),
        yaxis = list(title = "Puntuación Promedio"),
        dragmode = "select"
      ) %>%
      config(displayModeBar = TRUE)
    
    return(p)
  })
  
  # Tabla de detalles - NO FUNCIONA
  output$selectedAnimeDetails <- renderDT({
    event_data <- event_data("plotly_selected", source = "anime_scatter")
    df <- datos_filtrados()
    
    if (is.null(event_data) || nrow(event_data) == 0) {
      return(datatable(
        data.frame(Nota = "Selecciona puntos en el gráfico para ver detalles de los animes"),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    # Obtener los IDs de los puntos seleccionados
    selected_ids <- event_data$customdata
    
    # Filtrar los animes seleccionados usando los IDs
    selected_data <- df %>%
      filter(row_number() %in% selected_ids) %>%
      select(
        Título = title,
        Tipo = type,
        Puntuación = score,
        Miembros = members,
        Episodios = episodes,
        Clasificación = rated,
        Estudio = producers,
        Géneros = genres
      ) %>%
      arrange(desc(Puntuación))
    
    datatable(
      selected_data,
      options = list(
        pageLength = 5,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      extensions = 'Buttons',
      rownames = FALSE
    )
  })
  
  # 8. Nube de palabras con títulos
  output$titleWordcloudPlot <- renderPlot({
    df <- datos_filtrados()
    
    if (nrow(df) > 0) {
      titulos <- tolower(paste(df$title, collapse = " "))
      corpus <- Corpus(VectorSource(titulos))
      corpus <- tm_map(corpus, content_transformer(tolower))
      corpus <- tm_map(corpus, removePunctuation)
      corpus <- tm_map(corpus, removeNumbers)
      corpus <- tm_map(corpus, removeWords, c(stopwords("spanish"), "anime"))
      corpus <- tm_map(corpus, stripWhitespace)
      
      dtm <- TermDocumentMatrix(corpus)
      m <- as.matrix(dtm)
      palabras <- sort(rowSums(m), decreasing = TRUE)
      df_palabras <- data.frame(word = names(palabras), freq = palabras)
      
      tema <- input$tema_anime
      paleta <- anime_palettes[[tema]]
      
      par(bg = paleta$wordcloud_bg, mar = c(0, 0, 2, 0))
      wordcloud(words = df_palabras$word, freq = df_palabras$freq, 
                min.freq = 2, max.words = 200, random.order = FALSE, 
                rot.per = 0.35, scale = c(6, 1.5),
                colors = brewer.pal(8, "Dark2"))
    } else {
      plot.new()
      text(0.5, 0.5, "No hay datos con los filtros seleccionados", cex = 1.5)
    }
  })
  
  # 9. Distribución de tipos
  output$typeDistributionPlot2 <- renderPlot({
    df <- datos_filtrados()
    
    if (nrow(df) > 0) {
      types <- df %>%
        count(type) %>%
        arrange(desc(n))
      
      ggplot(types, aes(x = reorder(type, n), y = n, fill = type)) +
        geom_col(show.legend = FALSE) +
        coord_flip() +
        geom_text(aes(label = n), hjust = -0.3, size = 4) +
        get_palette() +
        labs(x = "Tipo",
             y = "Cantidad") +
        theme_minimal(base_size = 14) +
        theme(
          plot.title = element_blank(),
          panel.grid.major.y = element_blank()
        )
    } else {
      ggplot() + 
        annotate("text", x = 1, y = 1, size = 6, 
                 label = "No hay datos con los filtros seleccionados") +
        theme_void()
    }
  })
  
  # 10. Tabla de datos completa
  output$fullDataTable <- renderDT({
    df <- datos_filtrados()
    
    if(nrow(df) > 0) {
      df %>%
        select(Título = title, Tipo = type, 
               Episodios = episodes, Puntuación = score, 
               Miembros = members, Clasificación = rated) %>%
        arrange(desc(Puntuación)) %>%
        datatable(options = list(
          pageLength = 10,
          autoWidth = TRUE,
          scrollX = TRUE,
          language = list(
            url = '//cdn.datatables.net/plug-ins/1.10.25/i18n/Spanish.json'
          )
        ), rownames = FALSE, 
        filter = 'top',
        extensions = c('Responsive', 'Buttons'),
        class = "display nowrap")
    } else {
      datatable(data.frame(Mensaje = "No hay datos con los filtros seleccionados"), 
                options = list(dom = 't'))
    }
  })
}

# Ejecutar la app
shinyApp(ui = ui, server = server)
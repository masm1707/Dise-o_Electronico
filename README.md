# 📍 Proyecto API de Reportes Geográficos

Este proyecto implementa una **API REST** para recibir y servir reportes con coordenadas GPS, fecha e imagen en base64, junto con una **página web** que muestra estos reportes en un mapa interactivo.


## 🎯 Objetivo

Crear una API funcional y una interfaz web que permita:  
- Recibir reportes con ubicación, fecha y foto.  
- Almacenar los reportes en una base de datos local.  
- Visualizar los reportes en un mapa con imágenes asociadas.


## 🚀 Tecnologías

- Backend: Python Flask
- Base de datos: SQLite
- Frontend: HTML, CSS, JavaScript + Leaflet para mapas  
- Documentación: OpenAPI (archivo `openapi.yaml`) con Swagger Viewer

---

## 📚 Documentación de la API

La documentación oficial de la API se encuentra en el archivo [`openapi.yaml`](./openapi.yaml) ✨

Puedes visualizarla fácilmente con herramientas como:  
- [Swagger Editor Online](https://swagger.io/tools/swagger-editor/)  
- La extensión **Swagger Viewer** en VSCode (busca la extensión en el marketplace)  

---

## 🛠 Uso

### Pruebas de la API  
Puedes probar los endpoints usando:  
- [Thunder Client](https://marketplace.visualstudio.com/items?itemName=rangav.vscode-thunder-client) (extensión VSCode)  

### Endpoints principales  

| Método | Ruta       | Descripción                      |
|--------|------------|--------------------------------|
| POST   | `/reportes` | Crear un nuevo reporte           |
| GET    | `/reportes` | Obtener todos los reportes       |
| DELETE | `/borrar_todos` | Borrar todos los reportes (botón en la parte superior izquierda de la página web) |

---

## 🗺 Visualización Web

La página web consume el endpoint GET `/reportes` y muestra:  
- Marcadores en un mapa interactivo (Leaflet)  
- Información detallada y foto (al hacer clic desde la lista de reportes para agrandarla)
- Permite borrar todos los reportes realizados con anterioridad con botón

---

## 📂 Estructura del repositorio


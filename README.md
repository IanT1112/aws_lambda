# Image Processor — Infraestructura como Código

Arquitectura en AWS para subir y procesar imágenes, desplegada con Terraform en tres entornos: dev, qa y prod.

---

## Requisitos necesarios

Tener instalado Terraform, AWS CLI y Node.js

Configurar las credenciales de AWS ejecutando `aws configure` e ingresando el Access Key ID, Secret Access Key, región us-east-1 y formato json.

Verificar la conexión con `aws sts get-caller-identity`.

---

## Instalación de dependencias

Ingresar a la carpeta `lambdas/upload-lambda` y ejecutar `npm install`.

Ingresar a la carpeta `lambdas/crop-lambda` y ejecutar `npm install --os=linux --cpu=x64 --libc=glibc`. Este comando es necesario porque la librería sharp requiere binarios compilados para Linux (acá se tuvo problemas), que es el entorno donde ejecuta Lambda, independientemente del sistema operativo de desarrollo.

---

## Configuración de entornos

Cada entorno tiene su propio archivo `terraform.tfvars` dentro de su carpeta correspondiente en `environments/`. Antes del primer despliegue, editar ese archivo en cada entorno y reemplazar el valor de `suffix` por un identificador único personal. Este valor se usa para garantizar que el nombre del bucket S3 sea único globalmente en AWS.

Los archivos `terraform.tfvars` están incluidos en `.gitignore` por contener datos sensibles y se evita subir al repositorio.

---

## Despliegue

Para desplegar el entorno dev, ingresar a `environments/dev` y ejecutar los siguientes comandos en orden.

`terraform init` descarga los providers necesarios de AWS.

`terraform plan` muestra los recursos que se van a crear sin crearlos.

`terraform apply` crea todos los recursos en AWS. Confirmar escribiendo yes cuando lo solicite.

Al finalizar, Terraform muestra la URL del endpoint y el nombre del bucket creado.

Repetir el mismo proceso para qa ingresando a `environments/qa` y para prod ingresando a `environments/prod`.

---

## Prueba del endpoint

Desde PowerShell en Windows, ejecutar lo siguiente reemplazando la ruta de la imagen y la URL del endpoint con los valores reales.

```powershell
$image = [Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\ruta\imagen.jpg"))
$body = '{"image":"' + $image + '","contentType":"image/jpeg"}'
Invoke-RestMethod -Uri "https://<api-endpoint>/upload" -Method POST -ContentType "application/json" -Body $body
```

La respuesta esperada indica que la imagen fue subida correctamente e incluye la clave del archivo en S3.

Luego de unos 30 segundos, ingresar al bucket en la consola de AWS y verificar que la imagen original aparece en la carpeta `uploads/` y la imagen recortada aparece en `processed/` con el sufijo `_circular.png`. La imagen de salida es un PNG de 40x40 px con recorte circular y fondo transparente.

Los formatos de imagen aceptados son jpeg, png, gif y webp. El tamaño máximo es 10 MB.

---

## Destruir recursos

Ejecutar `terraform destroy` dentro de cada carpeta de entorno, comenzando por prod, luego qa y finalmente dev. Confirmar escribiendo yes cuando lo solicite.

Algunos recursos pueden requerir eliminación manual desde la consola de AWS.

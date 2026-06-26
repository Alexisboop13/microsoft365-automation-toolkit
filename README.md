# Microsoft 365 Automation Toolkit 🛠️

Scripts de PowerShell para automatización masiva de operaciones en Microsoft 365
vía Exchange Management Shell y Microsoft Graph API.

Desarrollados y usados en producción en una institución con **3,000+ usuarios**,
reduciendo procesos manuales de **6 días a 20 minutos**.

---

## 📁 Estructura

```
microsoft365-automation-toolkit/
├── contactos/
│   └── importar-contactos.ps1       # Importación masiva desde CSV con validación de duplicados
├── licencias/
│   ├── asignar-licencias.ps1        # Asignación masiva por perfil (E3, E1, etc.)
│   ├── auditar-licencias.ps1        # Reporte CSV de licencias actuales por usuario
│   └── quitar-licencias.ps1        # Remoción masiva con verificación previa
└── usuarios/
    ├── importar-usuarios.ps1        # Importación masiva a listas de distribución
    └── exportar-usuarios-masivo.ps1 # Exportación sin límite (+1,000 usuarios)
```

---

## 📋 Scripts

### 👥 Usuarios

**`importar-usuarios.ps1`**
Carga masiva de correos a una lista de distribución en Exchange.
Valida formato, elimina duplicados y genera reporte de resultados con timestamp.

**`exportar-usuarios-masivo.ps1`**
Exporta todos los miembros de una lista de distribución a CSV.
Usa `-ResultSize Unlimited` para superar el límite por defecto de 1,000 registros de Exchange.

---

### 🔑 Licencias

**`asignar-licencias.ps1`**
Asignación masiva de licencias Microsoft 365 vía Microsoft Graph API.
Soporta múltiples perfiles configurables (E3 + Security, E1 + Defender, etc.).
Establece `UsageLocation` automáticamente si el usuario no lo tiene configurado.

**`quitar-licencias.ps1`**
Remoción masiva de licencias con verificación previa.
Solo quita licencias que el usuario realmente tiene — evita errores `BadRequest`
en operaciones masivas.

**`auditar-licencias.ps1`**
Genera reporte CSV con las licencias actuales de una lista de usuarios.
Clasifica por perfil (E3, E1, Sin licencia) e incluye SKUs en bruto para auditoría.
Operación de solo lectura — no modifica nada.

---

### 📇 Contactos

**`importar-contactos.ps1`**
Importación masiva de contactos externos desde CSV.
Verifica duplicados contra Exchange antes de crear cada contacto.

**Formato del CSV requerido:**
```csv
Name,FirstName,LastName,ExternalEmailAddress
Juan Lopez,Juan,Lopez,juan.lopez@externo.com
```

---

## ⚙️ Requisitos

**Para scripts de Exchange (usuarios, contactos):**
- Exchange Management Shell conectado a tu tenant

**Para scripts de licencias (Microsoft Graph):**
- PowerShell 5.1+
- Módulo Microsoft.Graph:
  ```powershell
  Install-Module Microsoft.Graph -Scope CurrentUser
  ```
- Conectado con los permisos necesarios:
  ```powershell
  Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
  ```

---

## 🔒 Buenas prácticas incluidas

- Variables de configuración separadas del código — fácil de adaptar a cualquier tenant
- Validación de datos antes de ejecutar operaciones masivas
- Manejo de errores con `try/catch` — ningún error se ignora silenciosamente
- Reportes automáticos con timestamp para auditoría
- Scripts de licencias verifican el estado actual antes de modificar
- Sin credenciales ni datos reales en el código

---

## 👤 Autor

**Alexis Dehesa**
GitHub: [@Alexisboop13](https://github.com/Alexisboop13)
LinkedIn: [Alexis Dehesa](https://www.linkedin.com/in/alexis-ismael-dehesa-guzman)

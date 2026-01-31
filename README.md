 # Alke Wallet Database

Base de datos relacional para la billetera digital **Alke Wallet**, diseñada sobre MySQL 8.4 con foco en integridad, trazabilidad y consultas analíticas básicas.

## Características principales
- Modelo normalizado con tablas `usuario_tbl`, `moneda_tbl` y `transaccion_tbl` más claves foráneas y restricciones `CHECK`.
- Scripts transaccionales de ejemplo (COMMIT/ROLLBACK) y generación masiva de movimientos mediante CTE.
- Conjunto de consultas didácticas (`consultas_billetera_digital.sql`) que cubre SELECT básicos, filtros dinámicos, JOINs, subconsultas, agregaciones y una vista `vw_top5_saldos_usuario`.
- Registro automatizado de todas las sentencias SQL en `scripts/sentencias_alke_wallet.docx` generado por `generar_doc_sentencias.py`.

## Requisitos
- MySQL Server 8.4+
- Python 3.12+ (solo para regenerar el documento Word)

## Estructura relevante
```
database/
├── scripts/
│   ├── billetera_digital.sql          # Script maestro (DDL + DML + consulta
│   ├── consultas_billetera_digital.sql# Consultas de la lección 2
│   ├── generar_doc_sentencias.py      # Genera el Word con todas las sentencias
│   └── sentencias_alke_wallet.docx    # Bitácora de sentencias (autoactualizable)
└── README.md
```

## Puesta en marcha
1. Conectar al servidor MySQL 8.4 y ejecutar el script maestro:
   ```sql
   SOURCE scripts/billetera_digital.sql;
   ```
2. (Opcional) Cargar consultas adicionales:
   ```sql
   SOURCE scripts/consultas_billetera_digital.sql;
   ```
3. (Opcional) Regenerar el Word con las sentencias si modificas algún script:
   ```bash
   python scripts/generar_doc_sentencias.py
   ```

## Documentación y evidencias
- Diagramas y modelos se encuentran en `modelos/`.
- Evidencias visuales en `screenshoot/`.
- Toda instrucción SQL ejecutada queda consolidada en `scripts/sentencias_alke_wallet.docx`.

## Próximos pasos sugeridos
- Integrar la capa de aplicación (API o backend) apuntando a `alkewallet_db`.
- Añadir pruebas automatizadas que validen triggers, restricciones y consultas frecuentes.
- Versionar migraciones futuras con una herramienta como Liquibase o Flyway.

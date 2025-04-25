from django.http import JsonResponse
from django.db import connection

def health_check(request):
    """
    Endpoint para verificar la salud de la aplicación.
    Comprueba la conexión a la base de datos y devuelve el estado.
    """
    status = 200
    db_status = "ok"
    
    # Verificar conexión a la base de datos
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
    except Exception as e:
        status = 503
        db_status = str(e)
    
    response = {
        "status": "ok" if status == 200 else "error",
        "database": db_status,
        "version": "1.0.0"
    }
    
    return JsonResponse(response, status=status)
from django.urls import path
from . import views

urlpatterns = [
    path('login/', views.login, name='login'),
    path('logout/', views.logout, name='logout'),
    path('tasks/', views.create_task, name='create_task'),
    path('manage_task/<int:task_id>/', views.manage_task, name='manage_task'),
]
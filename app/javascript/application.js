import "@hotwired/turbo-rails"
import "controllers"
import 'flowbite';
import Swal from 'sweetalert2';
window.Swal = Swal;

function detectConfig(message) {
  if (/elimin|borrar|no se puede deshacer/i.test(message)) {
    return {
      icon: 'warning',
      iconColor: '#ef4444',
      confirmButtonColor: '#dc2626',
      confirmButtonText: 'Sí, eliminar',
      title: '¿Eliminar registro?',
    };
  }
  if (/cerrar|no podr/i.test(message)) {
    return {
      icon: 'warning',
      iconColor: '#f59e0b',
      confirmButtonColor: '#d97706',
      confirmButtonText: 'Sí, cerrar venta',
      title: '¿Cerrar venta?',
    };
  }
  return {
    icon: 'question',
    iconColor: '#7c3aed',
    confirmButtonColor: '#7c3aed',
    confirmButtonText: 'Confirmar',
    title: '¿Confirmar acción?',
  };
}

Turbo.config.forms.confirm = function(message, _element) {
  const cfg = detectConfig(message);
  return Swal.fire({
    title: cfg.title,
    text: message,
    icon: cfg.icon,
    iconColor: cfg.iconColor,
    showCancelButton: true,
    confirmButtonColor: cfg.confirmButtonColor,
    cancelButtonColor: '#6b7280',
    confirmButtonText: cfg.confirmButtonText,
    cancelButtonText: 'Cancelar',
    reverseButtons: true,
    focusCancel: true,
    customClass: {
      popup:         'swal-popup',
      title:         'swal-title',
      htmlContainer: 'swal-text',
      confirmButton: 'swal-confirm',
      cancelButton:  'swal-cancel',
    },
  }).then(result => result.isConfirmed);
};

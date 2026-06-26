import '../models/appointment.dart';
import '../models/barber.dart';
import '../models/notification_item.dart';
import '../models/service_category.dart';
import '../models/service_item.dart';

class MockData {
  static const categories = [
    ServiceCategory(id: '1', name: 'Cabelo', icon: 'content_cut'),
    ServiceCategory(id: '2', name: 'Barba', icon: 'face'),
    ServiceCategory(id: '3', name: 'Combo', icon: 'bolt'),
    ServiceCategory(id: '4', name: 'Sobrancelha', icon: 'visibility'),
  ];

  static const services = [
    ServiceItem(id: '1', name: 'Corte premium', durationMinutes: 45, price: 55),
    ServiceItem(id: '2', name: 'Barba completa', durationMinutes: 35, price: 40),
    ServiceItem(id: '3', name: 'Corte + barba', durationMinutes: 70, price: 85),
  ];

  static const barbers = [
    Barber(
      id: '1',
      name: 'Davi Marcomin',
      shopName: 'Barbearia Elite',
      imageUrl:
          'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?auto=format&fit=crop&w=900&q=80',
      rating: 4.9,
      startingPrice: 49.32,
      bio:
          'Especialista em degradê, barba desenhada e acabamento premium para quem gosta de sair pronto.',
    ),
    Barber(
      id: '2',
      name: 'Ricardo Anderson',
      shopName: 'Barbearia Pro',
      imageUrl:
          'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=900&q=80',
      rating: 4.7,
      startingPrice: 28.48,
      bio:
          'Atendimento preciso, agenda pontual e cortes modernos para rotina executiva.',
    ),
  ];

  static const appointments = [
    Appointment(
      id: '1',
      barberName: 'Lucas Andrade',
      serviceName: 'Corte + barba',
      dateLabel: 'Hoje',
      time: '15:30',
      status: 'confirmed',
      total: 85,
    ),
    Appointment(
      id: '2',
      barberName: 'Diego Martins',
      serviceName: 'Corte premium',
      dateLabel: '12 Jul',
      time: '10:00',
      status: 'pending',
      total: 55,
    ),
  ];

  static const notifications = [
    NotificationItem(
      id: '1',
      title: 'Agendamento confirmado',
      message: 'Seu horário de hoje às 15:30 está garantido.',
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Pontos adicionados',
      message: 'Você ganhou 85 pontos no Clube da Régua.',
      isRead: true,
    ),
  ];

  static const times = ['09:00', '10:30', '13:00', '14:30', '16:00', '18:00'];
}

import '../entities/outside_view.dart';
import '../entities/reference_class_entry.dart';
import '../entities/user_profile.dart';

abstract class OutsideViewRepository {
  Future<void> save(OutsideView view);
  Future<OutsideView?> getForCase(String caseId);
  Future<ReferenceClassEntry?> findReferenceClass(String category);
  Future<UserProfile> getUserProfile();
  Future<void> saveUserProfile(UserProfile profile);
}

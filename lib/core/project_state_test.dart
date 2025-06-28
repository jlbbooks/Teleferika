import 'package:teleferika/core/logger.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';

/// Simple test script to verify ProjectStateManager foundation
class ProjectStateTest {
  static Future<void> runTests() async {
    logger.info('Starting ProjectStateManager foundation tests...');
    
    final projectState = ProjectStateManager();
    final dbHelper = DatabaseHelper.instance;
    
    try {
      // Test 1: Check initial state
      logger.info('Test 1: Checking initial state...');
      assert(!projectState.hasProject, 'Should not have project initially');
      assert(projectState.currentPoints.isEmpty, 'Should have no points initially');
      assert(!projectState.isLoading, 'Should not be loading initially');
      logger.info('✅ Test 1 passed: Initial state is correct');
      
      // Test 2: Load projects from database
      logger.info('Test 2: Loading projects from database...');
      final projects = await dbHelper.getAllProjects();
      logger.info('Found ${projects.length} projects in database');
      
      if (projects.isEmpty) {
        logger.warning('No projects found in database. Creating a test project...');
        await _createTestProject(dbHelper);
        final projectsAfterCreate = await dbHelper.getAllProjects();
        if (projectsAfterCreate.isNotEmpty) {
          logger.info('✅ Test 2 passed: Created and found test project');
        } else {
          throw Exception('Failed to create test project');
        }
      } else {
        logger.info('✅ Test 2 passed: Found existing projects');
      }
      
      // Test 3: Load a project into global state
      logger.info('Test 3: Loading project into global state...');
      final testProjects = await dbHelper.getAllProjects();
      if (testProjects.isNotEmpty) {
        final testProject = testProjects.first;
        await projectState.loadProject(testProject.id);
        
        assert(projectState.hasProject, 'Should have project after loading');
        assert(projectState.currentProject != null, 'Current project should not be null');
        assert(projectState.currentProject!.id == testProject.id, 'Project ID should match');
        logger.info('✅ Test 3 passed: Project loaded into global state');
        
        // Test 4: Add a point
        logger.info('Test 4: Adding a test point...');
        final originalPointCount = projectState.currentPoints.length;
        final newPoint = PointModel(
          projectId: testProject.id,
          latitude: 45.123456,
          longitude: 12.345678,
          ordinalNumber: originalPointCount,
          note: 'Test point added at ${DateTime.now()}',
        );
        
        await projectState.addPoint(newPoint);
        
        assert(projectState.currentPoints.length == originalPointCount + 1, 
               'Point count should increase by 1');
        logger.info('✅ Test 4 passed: Point added successfully');
        
        // Test 5: Update a point
        logger.info('Test 5: Updating a point...');
        final pointToUpdate = projectState.currentPoints.last;
        final updatedPoint = pointToUpdate.copyWith(
          note: 'Updated at ${DateTime.now()}',
        );
        
        await projectState.updatePoint(updatedPoint);
        
        final updatedPointInState = projectState.getPointById(pointToUpdate.id);
        assert(updatedPointInState != null, 'Updated point should exist');
        assert(updatedPointInState!.note != pointToUpdate.note, 'Note should be updated');
        logger.info('✅ Test 5 passed: Point updated successfully');
        
        // Test 6: Delete a point
        logger.info('Test 6: Deleting a point...');
        final pointToDelete = projectState.currentPoints.last;
        final pointCountBeforeDelete = projectState.currentPoints.length;
        
        await projectState.deletePoint(pointToDelete.id);
        
        assert(projectState.currentPoints.length == pointCountBeforeDelete - 1,
               'Point count should decrease by 1');
        assert(projectState.getPointById(pointToDelete.id) == null,
               'Deleted point should not exist');
        logger.info('✅ Test 6 passed: Point deleted successfully');
        
        // Test 7: Clear project
        logger.info('Test 7: Clearing project...');
        projectState.clearProject();
        
        assert(!projectState.hasProject, 'Should not have project after clearing');
        assert(projectState.currentPoints.isEmpty, 'Should have no points after clearing');
        logger.info('✅ Test 7 passed: Project cleared successfully');
      }
      
      logger.info('🎉 All ProjectStateManager foundation tests passed!');
      
    } catch (e, stackTrace) {
      logger.severe('❌ ProjectStateManager foundation test failed', e, stackTrace);
      rethrow;
    }
  }
  
  static Future<void> _createTestProject(DatabaseHelper dbHelper) async {
    final testProject = ProjectModel(
      name: 'Test Project ${DateTime.now().millisecondsSinceEpoch}',
      note: 'Test project for foundation testing',
      date: DateTime.now(),
    );
    
    await dbHelper.insertProject(testProject);
    logger.info('Created test project: ${testProject.name}');
  }
} 
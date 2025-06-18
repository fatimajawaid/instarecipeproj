import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/meal_plan_service.dart';
import '../models/recipe_model.dart';
import 'package:intl/intl.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final MealPlanService _mealPlanService = MealPlanService();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _mealPlanService.addListener(_onMealPlanChanged);
    _mealPlanService.initializeWithSampleData();
  }

  @override
  void dispose() {
    _mealPlanService.removeListener(_onMealPlanChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onMealPlanChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _goToGroceryList() {
    context.go('/grocery-list');
  }

  void _selectMealType(DateTime date) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFfcf9f8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF9a5e4c),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Meal for ${DateFormat('MMM d').format(date)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1b110d),
                ),
              ),
              const SizedBox(height: 24),
              _buildMealTypeOption('Breakfast', Icons.wb_sunny_outlined, date),
              _buildMealTypeOption('Lunch', Icons.lunch_dining_outlined, date),
              _buildMealTypeOption('Dinner', Icons.dinner_dining_outlined, date),
              _buildMealTypeOption('Snacks', Icons.cookie_outlined, date),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealTypeOption(String mealType, IconData icon, DateTime date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFFef6a42),
          size: 28,
        ),
        title: Text(
          mealType,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1b110d),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFF9a5e4c),
          size: 16,
        ),
        onTap: () {
          Navigator.pop(context);
          context.go('/meal-selection?date=${date.millisecondsSinceEpoch}&mealType=${mealType.toLowerCase()}');
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: const Color(0xFFf3eae7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfcf9f8),
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFFfcf9f8),
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF181311),
                        size: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 48),
                      child: Text(
                        'Meal Plan',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF1b110d),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.015,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calendar Section
                  _buildCalendarSection(),
                  
                  // This Week Section
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 16),
                    child: Row(
                      children: [
                        Text(
                          'This Week',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF1b110d),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.015,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _mealPlanService.goToToday(),
                          icon: const Icon(
                            Icons.today,
                            size: 16,
                            color: Color(0xFFef6a42),
                          ),
                          label: Text(
                            'Today',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFef6a42),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Weekly Meal Plans
                  _buildWeeklyMealPlans(),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          onPressed: _goToGroceryList,
          backgroundColor: const Color(0xFFef6a42),
          icon: const Icon(
            Icons.shopping_cart,
            color: Color(0xFFfcf9f8),
            size: 24,
          ),
          label: Text(
            'Grocery List',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFfcf9f8),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.015,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _buildCalendar(),
    );
  }

  Widget _buildCalendar() {
    DateTime currentMonth = _mealPlanService.currentMonth;
    List<List<DateTime?>> calendarWeeks = _mealPlanService.getCalendarWeeks(currentMonth);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Calendar Header
          Row(
            children: [
              IconButton(
                onPressed: _mealPlanService.goToPreviousMonth,
                icon: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF1b110d),
                  size: 28,
                ),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(currentMonth),
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF1b110d),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: _mealPlanService.goToNextMonth,
                icon: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF1b110d),
                  size: 28,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Day headers
          Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Expanded(
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        child: Text(
                          day,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF9a5e4c),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          
          // Calendar grid
          ...calendarWeeks.map((week) => _buildCalendarWeek(week)),
        ],
      ),
    );
  }

  Widget _buildCalendarWeek(List<DateTime?> week) {
    return Row(
      children: week.map((date) => _buildCalendarDay(date)).toList(),
    );
  }

  Widget _buildCalendarDay(DateTime? date) {
    if (date == null) {
      return const Expanded(child: SizedBox(height: 48));
    }

    bool isSelected = _mealPlanService.selectedDate != null &&
        _isSameDay(date, _mealPlanService.selectedDate!);
    bool isToday = _isSameDay(date, DateTime.now());
    bool hasPlannedMeals = _mealPlanService.hasPlannedMeals(date);
    bool isCurrentMonth = date.month == _mealPlanService.currentMonth.month;

    return Expanded(
      child: Container(
        height: 48,
        margin: const EdgeInsets.all(2),
        child: TextButton(
          onPressed: isCurrentMonth ? () {
            _mealPlanService.selectDate(date);
            _selectMealType(date);
          } : null,
          style: TextButton.styleFrom(
            backgroundColor: isSelected
                ? const Color(0xFFef6a42)
                : (isToday ? const Color(0xFFf3eae7) : Colors.transparent),
            foregroundColor: isSelected
                ? Colors.white
                : (isCurrentMonth ? const Color(0xFF1b110d) : const Color(0xFF9a5e4c)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '${date.day}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              if (hasPlannedMeals && !isSelected)
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFef6a42),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildWeeklyMealPlans() {
    List<MealPlan> weekMealPlans = _mealPlanService.getCurrentWeekMealPlans();
    List<String> weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return Column(
      children: weekMealPlans.asMap().entries.map((entry) {
        int index = entry.key;
        MealPlan mealPlan = entry.value;
        String dayName = weekDays[index];
        
        return _buildDayPlan(dayName, mealPlan);
      }).toList(),
    );
  }

  Widget _buildDayPlan(String dayName, MealPlan mealPlan) {
    bool hasPlannedMeals = mealPlan.hasMeals;
    String dateText = DateFormat('MMM d').format(mealPlan.date);
    bool isToday = _isSameDay(mealPlan.date, DateTime.now());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: isToday ? Border.all(
          color: const Color(0xFFef6a42),
          width: 2,
        ) : null,
      ),
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFFef6a42) : const Color(0xFFf3eae7),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              '${mealPlan.date.day}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isToday ? Colors.white : const Color(0xFF1b110d),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  dayName,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF1b110d),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateText,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF9a5e4c),
                    fontSize: 14,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFef6a42),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Today',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hasPlannedMeals ? mealPlan.mealSummary : 'No meals planned',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF9a5e4c),
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _selectMealType(mealPlan.date),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFef6a42),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize: const Size(80, 36),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Text(
            'Add meal',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        children: hasPlannedMeals ? _buildMealDetails(mealPlan) : [],
      ),
    );
  }

  List<Widget> _buildMealDetails(MealPlan mealPlan) {
    List<Widget> mealWidgets = [];

    void addMealSection(String mealType, List<Recipe> meals) {
      if (meals.isNotEmpty) {
        mealWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealType.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9a5e4c),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                ...meals.map((recipe) => _buildMealItem(recipe, mealPlan.date, mealType)),
              ],
            ),
          ),
        );
      }
    }

    addMealSection('Breakfast', mealPlan.breakfast);
    addMealSection('Lunch', mealPlan.lunch);
    addMealSection('Dinner', mealPlan.dinner);
    addMealSection('Snacks', mealPlan.snacks);

    return mealWidgets;
  }

  Widget _buildMealItem(Recipe recipe, DateTime date, String mealType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFf3eae7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              recipe.imageUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9a5e4c).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Color(0xFF9a5e4c),
                    size: 20,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1b110d),
                  ),
                ),
                Text(
                  '${recipe.cookingTimeMinutes} min • ${recipe.calories} cal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF9a5e4c),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _mealPlanService.removeMealFromDate(
              date: date,
              recipe: recipe,
              mealType: mealType,
            ),
            icon: const Icon(
              Icons.remove_circle_outline,
              color: Color(0xFF9a5e4c),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
} 
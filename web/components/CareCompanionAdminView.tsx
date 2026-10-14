import React, { useState, useEffect } from 'react';
import {
  SearchIcon,
  PlusIcon,
  EditIcon,
  TrashIcon,
  RotateCwIcon,
  CheckIcon,
  XIcon,
  AlertTriangleIcon,
  FileTextIcon,
} from './Icons';

interface MasterMeal {
  id: string;
  name: string;
  category: 'BREAKFAST' | 'LUNCH' | 'DINNER' | 'SNACK';
  portion: string;
  estimatedCostIdr: number;
  glycemicIndex: 'LOW' | 'MEDIUM' | 'HIGH';
  carbsGrams: number;
  proteinGrams: number;
  ingredients: string[];
  preparationNotes: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

interface MasterQuestion {
  id: string;
  questionText: string;
  category: string;
  orderIndex: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export function CareCompanionAdminView() {
  const [activeSubTab, setActiveSubTab] = useState<'meals' | 'questions'>('meals');
  const [meals, setMeals] = useState<MasterMeal[]>([]);
  const [questions, setQuestions] = useState<MasterQuestion[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [categoryFilter, setCategoryFilter] = useState<string>('ALL');

  // Modal States for Meal
  const [isAddMealModal, setIsAddMealModal] = useState<boolean>(false);
  const [editingMeal, setEditingMeal] = useState<MasterMeal | null>(null);
  const [deletingMeal, setDeletingMeal] = useState<MasterMeal | null>(null);

  // Modal States for Question
  const [isAddQuestionModal, setIsAddQuestionModal] = useState<boolean>(false);
  const [editingQuestion, setEditingQuestion] = useState<MasterQuestion | null>(null);
  const [deletingQuestion, setDeletingQuestion] = useState<MasterQuestion | null>(null);

  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [alertFeedback, setAlertFeedback] = useState<{ message: string; type: 'success' | 'danger' } | null>(null);

  // Form States
  const [mealForm, setMealForm] = useState({
    name: '',
    category: 'BREAKFAST' as MasterMeal['category'],
    portion: '1 Porsi',
    estimatedCostIdr: 10000,
    glycemicIndex: 'LOW' as MasterMeal['glycemicIndex'],
    carbsGrams: 25,
    proteinGrams: 15,
    ingredientsStr: '',
    preparationNotes: '',
    isActive: true,
  });

  const [questionForm, setQuestionForm] = useState({
    questionText: '',
    category: 'Pemeriksaan Retina',
    orderIndex: 1,
    isActive: true,
  });

  const showFeedback = (message: string, type: 'success' | 'danger') => {
    setAlertFeedback({ message, type });
    setTimeout(() => setAlertFeedback(null), 4000);
  };

  const fetchMeals = async () => {
    setIsLoading(true);
    try {
      const res = await fetch('/api/v1/master/meals');
      const data = await res.json();
      if (data.success && Array.isArray(data.data)) {
        setMeals(data.data);
      }
    } catch {
      showFeedback('Gagal memuat data menu master', 'danger');
    } finally {
      setIsLoading(false);
    }
  };

  const fetchQuestions = async () => {
    setIsLoading(true);
    try {
      const res = await fetch('/api/v1/master/questions');
      const data = await res.json();
      if (data.success && Array.isArray(data.data)) {
        setQuestions(data.data);
      }
    } catch {
      showFeedback('Gagal memuat data pertanyaan master', 'danger');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (activeSubTab === 'meals') {
      fetchMeals();
    } else {
      fetchQuestions();
    }
  }, [activeSubTab]);

  // Handle Meal Create / Edit
  const handleSaveMeal = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      const ingredients = mealForm.ingredientsStr
        .split('\n')
        .map((s) => s.trim())
        .filter(Boolean);

      const payload = {
        name: mealForm.name,
        category: mealForm.category,
        portion: mealForm.portion,
        estimatedCostIdr: Number(mealForm.estimatedCostIdr),
        glycemicIndex: mealForm.glycemicIndex,
        carbsGrams: Number(mealForm.carbsGrams),
        proteinGrams: Number(mealForm.proteinGrams),
        ingredients,
        preparationNotes: mealForm.preparationNotes,
        isActive: mealForm.isActive,
      };

      if (editingMeal) {
        const res = await fetch(`/api/v1/master/meals/${editingMeal.id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });
        const data = await res.json();
        if (data.success) {
          showFeedback('Menu makanan berhasil diperbarui di database', 'success');
          setEditingMeal(null);
          fetchMeals();
        } else {
          showFeedback(data.error || 'Gagal memperbarui menu', 'danger');
        }
      } else {
        const res = await fetch('/api/v1/master/meals', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });
        const data = await res.json();
        if (data.success) {
          showFeedback('Menu baru berhasil disimpan ke database master', 'success');
          setIsAddMealModal(false);
          fetchMeals();
        } else {
          showFeedback(data.error || 'Gagal menambahkan menu', 'danger');
        }
      }
    } catch {
      showFeedback('Terjadi kesalahan jaringan saat menyimpan data menu', 'danger');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handle Meal Delete
  const handleDeleteMeal = async () => {
    if (!deletingMeal) return;
    setIsSubmitting(true);
    try {
      const res = await fetch(`/api/v1/master/meals/${deletingMeal.id}`, {
        method: 'DELETE',
      });
      const data = await res.json();
      if (data.success) {
        showFeedback('Menu makanan berhasil dihapus dari database master', 'success');
        setDeletingMeal(null);
        fetchMeals();
      } else {
        showFeedback(data.error || 'Gagal menghapus menu', 'danger');
      }
    } catch {
      showFeedback('Gagal menghubungi server', 'danger');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handle Question Create / Edit
  const handleSaveQuestion = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      const payload = {
        questionText: questionForm.questionText,
        category: questionForm.category,
        orderIndex: Number(questionForm.orderIndex),
        isActive: questionForm.isActive,
      };

      if (editingQuestion) {
        const res = await fetch(`/api/v1/master/questions/${editingQuestion.id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });
        const data = await res.json();
        if (data.success) {
          showFeedback('Pertanyaan dokter berhasil diperbarui di database', 'success');
          setEditingQuestion(null);
          fetchQuestions();
        } else {
          showFeedback(data.error || 'Gagal memperbarui pertanyaan', 'danger');
        }
      } else {
        const res = await fetch('/api/v1/master/questions', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });
        const data = await res.json();
        if (data.success) {
          showFeedback('Pertanyaan dokter baru berhasil disimpan ke database', 'success');
          setIsAddQuestionModal(false);
          fetchQuestions();
        } else {
          showFeedback(data.error || 'Gagal menambahkan pertanyaan', 'danger');
        }
      }
    } catch {
      showFeedback('Terjadi kesalahan jaringan saat menyimpan data pertanyaan', 'danger');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handle Question Delete
  const handleDeleteQuestion = async () => {
    if (!deletingQuestion) return;
    setIsSubmitting(true);
    try {
      const res = await fetch(`/api/v1/master/questions/${deletingQuestion.id}`, {
        method: 'DELETE',
      });
      const data = await res.json();
      if (data.success) {
        showFeedback('Pertanyaan dokter berhasil dihapus dari database', 'success');
        setDeletingQuestion(null);
        fetchQuestions();
      } else {
        showFeedback(data.error || 'Gagal menghapus pertanyaan', 'danger');
      }
    } catch {
      showFeedback('Gagal menghubungi server', 'danger');
    } finally {
      setIsSubmitting(false);
    }
  };

  const openEditMeal = (m: MasterMeal) => {
    setEditingMeal(m);
    setMealForm({
      name: m.name,
      category: m.category,
      portion: m.portion,
      estimatedCostIdr: m.estimatedCostIdr,
      glycemicIndex: m.glycemicIndex,
      carbsGrams: m.carbsGrams,
      proteinGrams: m.proteinGrams,
      ingredientsStr: m.ingredients.join('\n'),
      preparationNotes: m.preparationNotes,
      isActive: m.isActive,
    });
  };

  const openAddMeal = () => {
    setEditingMeal(null);
    setMealForm({
      name: '',
      category: 'BREAKFAST',
      portion: '1 Porsi',
      estimatedCostIdr: 8000,
      glycemicIndex: 'LOW',
      carbsGrams: 25,
      proteinGrams: 12,
      ingredientsStr: 'Bahan 1\nBahan 2',
      preparationNotes: 'Catatan pengolahan rendah minyak dan rendah garam...',
      isActive: true,
    });
    setIsAddMealModal(true);
  };

  const openEditQuestion = (q: MasterQuestion) => {
    setEditingQuestion(q);
    setQuestionForm({
      questionText: q.questionText,
      category: q.category,
      orderIndex: q.orderIndex,
      isActive: q.isActive,
    });
  };

  const openAddQuestion = () => {
    setEditingQuestion(null);
    setQuestionForm({
      questionText: '',
      category: 'Pemeriksaan Retina',
      orderIndex: questions.length + 1,
      isActive: true,
    });
    setIsAddQuestionModal(true);
  };

  // Filtered Meals
  const filteredMeals = meals.filter((m) => {
    const matchCat = categoryFilter === 'ALL' || m.category === categoryFilter;
    const matchSearch =
      m.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      m.ingredients.some((ing) => ing.toLowerCase().includes(searchQuery.toLowerCase()));
    return matchCat && matchSearch;
  });

  // Filtered Questions
  const filteredQuestions = questions.filter((q) => {
    return (
      q.questionText.toLowerCase().includes(searchQuery.toLowerCase()) ||
      q.category.toLowerCase().includes(searchQuery.toLowerCase())
    );
  });

  const getCategoryLabel = (cat: string) => {
    switch (cat) {
      case 'BREAKFAST':
        return 'Sarapan Pagi';
      case 'LUNCH':
        return 'Makan Siang';
      case 'DINNER':
        return 'Makan Malam';
      case 'SNACK':
        return 'Camilan Sehat';
      default:
        return cat;
    }
  };

  const getGiBadge = (gi: string) => {
    switch (gi) {
      case 'LOW':
        return <span style={{ padding: '3px 8px', borderRadius: '6px', fontSize: '11px', fontWeight: 700, background: '#DCFCE7', color: '#166534' }}>IG Rendah</span>;
      case 'MEDIUM':
        return <span style={{ padding: '3px 8px', borderRadius: '6px', fontSize: '11px', fontWeight: 700, background: '#FEF3C7', color: '#92400E' }}>IG Sedang</span>;
      case 'HIGH':
        return <span style={{ padding: '3px 8px', borderRadius: '6px', fontSize: '11px', fontWeight: 700, background: '#FEE2E2', color: '#991B1B' }}>IG Tinggi</span>;
      default:
        return gi;
    }
  };

  return (
    <div style={{ padding: '1.5rem', maxWidth: '1400px', margin: '0 auto' }}>
      {/* Top Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h1 style={{ fontSize: '1.5rem', fontWeight: 800, color: '#0F172A', margin: 0 }}>
            Master Data Pendamping Perawatan (Care Companion)
          </h1>
          <p style={{ margin: '0.25rem 0 0 0', fontSize: '0.875rem', color: '#64748B' }}>
            Kelola katalog menu makanan rendah glikemik, estimasi biaya lokal, dan panduan pertanyaan konsultasi dokter yang tersimpan di PostgreSQL.
          </p>
        </div>

        {/* Action Button */}
        <div style={{ display: 'flex', gap: '0.75rem' }}>
          <button
            onClick={() => (activeSubTab === 'meals' ? fetchMeals() : fetchQuestions())}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              padding: '0.6rem 1rem',
              background: '#F1F5F9',
              border: '1px solid #CBD5E1',
              borderRadius: '8px',
              fontSize: '0.85rem',
              fontWeight: 600,
              color: '#334155',
              cursor: 'pointer',
            }}
          >
            <RotateCwIcon size={16} /> Refresh
          </button>
          <button
            onClick={() => (activeSubTab === 'meals' ? openAddMeal() : openAddQuestion())}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              padding: '0.6rem 1.15rem',
              background: '#0D47A1',
              border: 'none',
              borderRadius: '8px',
              fontSize: '0.85rem',
              fontWeight: 700,
              color: '#FFFFFF',
              cursor: 'pointer',
              boxShadow: '0 2px 8px rgba(13, 71, 161, 0.25)',
            }}
          >
            <PlusIcon size={16} /> {activeSubTab === 'meals' ? 'Tambah Menu Nutrisi' : 'Tambah Pertanyaan Dokter'}
          </button>
        </div>
      </div>

      {/* Alert Banner */}
      {alertFeedback && (
        <div
          style={{
            padding: '0.75rem 1rem',
            borderRadius: '8px',
            marginBottom: '1rem',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            background: alertFeedback.type === 'success' ? '#ECFDF5' : '#FEF2F2',
            color: alertFeedback.type === 'success' ? '#065F46' : '#991B1B',
            border: `1px solid ${alertFeedback.type === 'success' ? '#A7F3D0' : '#FECACA'}`,
            fontSize: '0.875rem',
            fontWeight: 600,
          }}
        >
          {alertFeedback.type === 'success' ? <CheckIcon size={18} /> : <AlertTriangleIcon size={18} />}
          {alertFeedback.message}
        </div>
      )}

      {/* Navigation Sub-Tabs */}
      <div style={{ display: 'flex', gap: '0.5rem', borderBottom: '2px solid #E2E8F0', marginBottom: '1.25rem' }}>
        <button
          onClick={() => {
            setActiveSubTab('meals');
            setSearchQuery('');
          }}
          style={{
            padding: '0.75rem 1.25rem',
            background: 'none',
            border: 'none',
            borderBottom: activeSubTab === 'meals' ? '3px solid #0D47A1' : '3px solid transparent',
            color: activeSubTab === 'meals' ? '#0D47A1' : '#64748B',
            fontWeight: activeSubTab === 'meals' ? 700 : 500,
            fontSize: '0.95rem',
            cursor: 'pointer',
            marginBottom: '-2px',
          }}
        >
          🍱 Menu Nutrisi Ramah Kantong ({meals.length})
        </button>
        <button
          onClick={() => {
            setActiveSubTab('questions');
            setSearchQuery('');
          }}
          style={{
            padding: '0.75rem 1.25rem',
            background: 'none',
            border: 'none',
            borderBottom: activeSubTab === 'questions' ? '3px solid #0D47A1' : '3px solid transparent',
            color: activeSubTab === 'questions' ? '#0D47A1' : '#64748B',
            fontWeight: activeSubTab === 'questions' ? 700 : 500,
            fontSize: '0.95rem',
            cursor: 'pointer',
            marginBottom: '-2px',
          }}
        >
          🩺 Daftar Pertanyaan Konsultasi Dokter ({questions.length})
        </button>
      </div>

      {/* Filter and Search Bar */}
      <div style={{ display: 'flex', gap: '1rem', marginBottom: '1.25rem', flexWrap: 'wrap' }}>
        <div style={{ position: 'relative', flex: '1 1 300px' }}>
          <span style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#94A3B8' }}>
            <SearchIcon size={16} />
          </span>
          <input
            type="text"
            placeholder={activeSubTab === 'meals' ? 'Cari nama menu atau bahan makanan...' : 'Cari teks pertanyaan dokter...'}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            style={{
              width: '100%',
              padding: '0.65rem 0.75rem 0.65rem 2.25rem',
              borderRadius: '8px',
              border: '1px solid #CBD5E1',
              fontSize: '0.875rem',
              outline: 'none',
              background: '#FFFFFF',
            }}
          />
        </div>

        {activeSubTab === 'meals' && (
          <select
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            style={{
              padding: '0.65rem 1rem',
              borderRadius: '8px',
              border: '1px solid #CBD5E1',
              fontSize: '0.875rem',
              fontWeight: 600,
              background: '#FFFFFF',
              color: '#334155',
              cursor: 'pointer',
            }}
          >
            <option value="ALL">Semua Waktu Makan</option>
            <option value="BREAKFAST">Sarapan Pagi</option>
            <option value="LUNCH">Makan Siang</option>
            <option value="DINNER">Makan Malam</option>
            <option value="SNACK">Camilan Sehat</option>
          </select>
        )}
      </div>

      {/* =====================================================================
          TAB 1: MEALS CRUD TABLE
         ===================================================================== */}
      {activeSubTab === 'meals' && (
        <div style={{ background: '#FFFFFF', borderRadius: '12px', border: '1px solid #E2E8F0', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
          {isLoading ? (
            <div style={{ padding: '3rem', textAlign: 'center', color: '#64748B' }}>
              <RotateCwIcon size={24} style={{ animation: 'spin 1s linear infinite' }} />
              <div style={{ marginTop: '0.5rem', fontWeight: 600 }}>Memuat data menu makanan dari PostgreSQL...</div>
            </div>
          ) : filteredMeals.length === 0 ? (
            <div style={{ padding: '3rem', textAlign: 'center', color: '#64748B' }}>
              <p style={{ margin: 0, fontWeight: 600 }}>Tidak ada menu yang sesuai dengan filter pencarian.</p>
            </div>
          ) : (
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.875rem' }}>
                <thead>
                  <tr style={{ background: '#F8FAFC', borderBottom: '1px solid #E2E8F0', color: '#475569', fontWeight: 700 }}>
                    <th style={{ padding: '0.85rem 1rem' }}>Nama Menu</th>
                    <th style={{ padding: '0.85rem 1rem' }}>Waktu Makan</th>
                    <th style={{ padding: '0.85rem 1rem' }}>Porsi &amp; Gizi</th>
                    <th style={{ padding: '0.85rem 1rem' }}>Estimasi Biaya</th>
                    <th style={{ padding: '0.85rem 1rem' }}>Indeks Glikemik</th>
                    <th style={{ padding: '0.85rem 1rem' }}>Bahan-bahan</th>
                    <th style={{ padding: '0.85rem 1rem', textAlign: 'center' }}>Aksi</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredMeals.map((meal) => (
                    <tr key={meal.id} style={{ borderBottom: '1px solid #F1F5F9' }}>
                      <td style={{ padding: '0.85rem 1rem', fontWeight: 700, color: '#0F172A' }}>
                        {meal.name}
                        {meal.preparationNotes && (
                          <div style={{ fontSize: '0.75rem', fontWeight: 400, color: '#64748B', marginTop: '3px' }}>
                            {meal.preparationNotes}
                          </div>
                        )}
                      </td>
                      <td style={{ padding: '0.85rem 1rem', color: '#334155' }}>
                        <span style={{ padding: '3px 8px', borderRadius: '4px', background: '#EFF6FF', color: '#1E40AF', fontSize: '0.8rem', fontWeight: 600 }}>
                          {getCategoryLabel(meal.category)}
                        </span>
                      </td>
                      <td style={{ padding: '0.85rem 1rem', color: '#334155' }}>
                        <div style={{ fontWeight: 600 }}>{meal.portion}</div>
                        <div style={{ fontSize: '0.75rem', color: '#64748B' }}>
                          Karbo: {meal.carbsGrams}g • Protein: {meal.proteinGrams}g
                        </div>
                      </td>
                      <td style={{ padding: '0.85rem 1rem', fontWeight: 700, color: '#0D47A1' }}>
                        Rp {meal.estimatedCostIdr.toLocaleString('id-ID')}
                      </td>
                      <td style={{ padding: '0.85rem 1rem' }}>
                        {getGiBadge(meal.glycemicIndex)}
                      </td>
                      <td style={{ padding: '0.85rem 1rem', maxWidth: '240px', color: '#475569', fontSize: '0.8rem' }}>
                        {meal.ingredients.join(', ')}
                      </td>
                      <td style={{ padding: '0.85rem 1rem', textAlign: 'center' }}>
                        <div style={{ display: 'flex', justifyContent: 'center', gap: '0.5rem' }}>
                          <button
                            onClick={() => openEditMeal(meal)}
                            style={{
                              padding: '5px 8px',
                              background: '#F1F5F9',
                              border: '1px solid #CBD5E1',
                              borderRadius: '6px',
                              color: '#1E293B',
                              cursor: 'pointer',
                            }}
                            title="Edit Menu"
                          >
                            <EditIcon size={14} />
                          </button>
                          <button
                            onClick={() => setDeletingMeal(meal)}
                            style={{
                              padding: '5px 8px',
                              background: '#FEE2E2',
                              border: '1px solid #FCA5A5',
                              borderRadius: '6px',
                              color: '#B91C1C',
                              cursor: 'pointer',
                            }}
                            title="Hapus Menu"
                          >
                            <TrashIcon size={14} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* =====================================================================
          TAB 2: DOCTOR QUESTIONS CRUD TABLE
         ===================================================================== */}
      {activeSubTab === 'questions' && (
        <div style={{ background: '#FFFFFF', borderRadius: '12px', border: '1px solid #E2E8F0', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
          {isLoading ? (
            <div style={{ padding: '3rem', textAlign: 'center', color: '#64748B' }}>
              <RotateCwIcon size={24} style={{ animation: 'spin 1s linear infinite' }} />
              <div style={{ marginTop: '0.5rem', fontWeight: 600 }}>Memuat daftar pertanyaan dokter dari PostgreSQL...</div>
            </div>
          ) : filteredQuestions.length === 0 ? (
            <div style={{ padding: '3rem', textAlign: 'center', color: '#64748B' }}>
              <p style={{ margin: 0, fontWeight: 600 }}>Tidak ada pertanyaan dokter yang ditemukan.</p>
            </div>
          ) : (
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.875rem' }}>
                <thead>
                  <tr style={{ background: '#F8FAFC', borderBottom: '1px solid #E2E8F0', color: '#475569', fontWeight: 700 }}>
                    <th style={{ padding: '0.85rem 1rem', width: '60px' }}>No.</th>
                    <th style={{ padding: '0.85rem 1rem' }}>Teks Pertanyaan untuk Dokter Spesialis Mata</th>
                    <th style={{ padding: '0.85rem 1rem' }}>Kategori Klinis</th>
                    <th style={{ padding: '0.85rem 1rem' }}>Status</th>
                    <th style={{ padding: '0.85rem 1rem', textAlign: 'center' }}>Aksi</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredQuestions.map((q, idx) => (
                    <tr key={q.id} style={{ borderBottom: '1px solid #F1F5F9' }}>
                      <td style={{ padding: '0.85rem 1rem', fontWeight: 700, color: '#64748B' }}>
                        {q.orderIndex || idx + 1}
                      </td>
                      <td style={{ padding: '0.85rem 1rem', fontWeight: 600, color: '#0F172A' }}>
                        {q.questionText}
                      </td>
                      <td style={{ padding: '0.85rem 1rem' }}>
                        <span style={{ padding: '3px 8px', borderRadius: '4px', background: '#F1F5F9', color: '#334155', fontSize: '0.8rem', fontWeight: 600 }}>
                          {q.category}
                        </span>
                      </td>
                      <td style={{ padding: '0.85rem 1rem' }}>
                        <span style={{ padding: '3px 8px', borderRadius: '4px', background: q.isActive ? '#DCFCE7' : '#F1F5F9', color: q.isActive ? '#166534' : '#64748B', fontSize: '0.8rem', fontWeight: 700 }}>
                          {q.isActive ? 'Aktif' : 'Nonaktif'}
                        </span>
                      </td>
                      <td style={{ padding: '0.85rem 1rem', textAlign: 'center' }}>
                        <div style={{ display: 'flex', justifyContent: 'center', gap: '0.5rem' }}>
                          <button
                            onClick={() => openEditQuestion(q)}
                            style={{
                              padding: '5px 8px',
                              background: '#F1F5F9',
                              border: '1px solid #CBD5E1',
                              borderRadius: '6px',
                              color: '#1E293B',
                              cursor: 'pointer',
                            }}
                            title="Edit Pertanyaan"
                          >
                            <EditIcon size={14} />
                          </button>
                          <button
                            onClick={() => setDeletingQuestion(q)}
                            style={{
                              padding: '5px 8px',
                              background: '#FEE2E2',
                              border: '1px solid #FCA5A5',
                              borderRadius: '6px',
                              color: '#B91C1C',
                              cursor: 'pointer',
                            }}
                            title="Hapus Pertanyaan"
                          >
                            <TrashIcon size={14} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* =====================================================================
          MODAL: TAMBAH / EDIT MENU MAKANAN
         ===================================================================== */}
      {(isAddMealModal || editingMeal) && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: '1rem' }}>
          <div style={{ background: '#FFFFFF', borderRadius: '14px', width: '100%', maxWidth: '600px', maxHeight: '90vh', overflowY: 'auto', padding: '1.5rem', boxShadow: '0 10px 25px rgba(0,0,0,0.2)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem' }}>
              <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#0F172A', margin: 0 }}>
                {editingMeal ? 'Edit Menu Makanan Nutrisi' : 'Tambah Menu Nutrisi Baru'}
              </h2>
              <button
                onClick={() => {
                  setIsAddMealModal(false);
                  setEditingMeal(null);
                }}
                style={{ background: 'none', border: 'none', color: '#64748B', cursor: 'pointer' }}
              >
                <XIcon size={20} />
              </button>
            </div>

            <form onSubmit={handleSaveMeal}>
              <div style={{ marginBottom: '1rem' }}>
                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 700, color: '#334155', marginBottom: '4px' }}>
                  Nama Menu Makanan *
                </label>
                <input
                  type="text"
                  required
                  value={mealForm.name}
                  onChange={(e) => setMealForm({ ...mealForm, name: e.target.value })}
                  placeholder="Contoh: Nasi Merah Telur Rebus & Sayur Bayam"
                  style={{ width: '100%', padding: '0.6rem 0.75rem', borderRadius: '8px', border: '1px solid #CBD5E1', fontSize: '0.875rem' }}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1rem' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 700, color: '#334155', marginBottom: '4px' }}>
                    Waktu Makan *
                  </label>
                  <select
                    value={mealForm.category}
                    onChange={(e) => setMealForm({ ...mealForm, category: e.target.value as any })}
                    style={{ width: '100%', padding: '0.6rem 0.75rem', borderRadius: '8px', border: '1px solid #CBD5E1', fontSize: '0.875rem' }}
                  >
                    <option value="BREAKFAST">Sarapan Pagi</option>
                    <option value="LUNCH">Makan Siang</option>
                    <option value="DINNER">Makan Malam</option>
                    <option value="SNACK">Camilan Sehat</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 700, color: '#334155', marginBottom: '4px' }}>
                    Indeks Glikemik (IG) *
                  </label>
                  <select
                    value={mealForm.glycemicIndex}
                    onChange={(e) => setMealForm({ ...mealForm, glycemicIndex: e.target.value as any })}
                    style={{ width: '100%', padding: '0.6rem 0.75rem', borderRadius: '8px', border: '1px solid #CBD5E1', fontSize: '0.875rem' }}
                  >
                    <option value="LOW">Rendah (Low GI &lt; 55) - Direkomendasikan</option>
                    <option value="MEDIUM">Sedang (Medium GI 56-69)</option>
                    <option value="HIGH">Tinggi (High GI &gt; 70)</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '0.75rem', marginBottom: '1rem' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 700, color: '#334155', marginBottom: '4px' }}>
                    Estimasi Biaya (Rp) *
                  </label>
                  <input
                    type="number"
                    required
                    min={500}
                    step={500}
                    value={mealForm.estimatedCostIdr}
                    onChange={(e) => setMealForm({ ...mealForm, estimatedCostIdr: Number(e.target.value) })}
                    style={{ width: '100%', padding: '0.6rem 0.75rem', borderRadius: '8px', border: '1px solid #CBD5E1', fontSize: '0.875rem' }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 700, color: '#334155', marginBottom: '4px' }}>
                    Karbohidrat (g)
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={mealForm.carbsGrams}
                    onChange={(e) => setMealForm({ ...mealForm, carbsGrams: Number(e.target.value) })}
                    style={{ width: '100%', padding: '0.6rem 0.75rem', borderRadius: '8px', border: '1px solid #CBD5E1', fontSize: '0.875rem' }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 700, color: '#334155', marginBottom: '4px' }}>
                    Protein (g)
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={mealForm.proteinGrams}
                    onChange={(e) => setMealForm({ ...mealForm, proteinGrams: Number(e.target.value) })}
                    style={{ width: '100%', padding: '0.6rem 0.75rem', borderRadius: '8px', border: '1px solid #CBD5E1', fontSize: '0.875rem' }}
                  />
                </div>
              </div>

              <div style={{ marginBottom: '1rem' }}>
                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 700, color: '#334155', marginBottom: '4px' }}>
                  Bahan-bahan Utama (Tulis per baris)
                </label>
                <textarea
                  rows={3}
                  value={mealForm.ingredientsStr}
                  onChange={(e) => setMealForm({ ...mealForm, ingredientsStr: e.target.value })}
                  placeholder="Beras Merah (75g)&#10;Telur Ayam (1 butir)&#10;Bayam Segar"
                  style={{ width: '100%', padding: '0.6rem 0.75rem', borderRadius: '8px', border: '1px solid #CBD5E1', fontSize: '0.875rem' }}
                />
              </div>

              <div style={{ marginBottom: '1.25rem' }}>
                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 700, color: '#334155', marginBottom: '4px' }}>
                  Catatan Pengolahan Klinis
                </label>
                <textarea
                  rows={2}
                  value={mealForm.preparationNotes}
                  onChange={(e) => setMealForm({ ...mealForm, preparationNotes: e.target.value })}
                  placeholder="Kukus atau rebus tanpa digoreng minyak berlebih. Batasi natrium..."
                  style={{ width: '100%', padding: '0.6rem 0.75rem', borderRadius: '8px', border: '1px solid #CBD5E1', fontSize: '0.875rem' }}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
                <button
                  type="button"
                  onClick={() => {
                    setIsAddMealModal(false);
                    setEditingMeal(null);
                  }}
                  style={{ padding: '0.6rem 1.25rem', background: '#F1F5F9', border: '1px solid #CBD5E1', borderRadius: '8px', fontWeight: 600, color: '#475569', cursor: 'pointer' }}
                >
                  Batal
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  style={{ padding: '0.6rem 1.5rem', background: '#0D47A1', border: 'none', borderRadius: '8px', fontWeight: 700, color: '#FFFFFF', cursor: 'pointer' }}
                >
                  {isSubmitting ? 'Menyimpan...' : 'Simpan Menu ke Database'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* =====================================================================
          MODAL: TAMBAH / EDIT PERTANYAAN DOKTER
         ===================================================================== */}
      {(isAddQuestionModal || editingQuestion) && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: '1rem' }}>
          <div style={{ background: '#FFFFFF', borderRadius: '14px', width: '100%', maxWidth: '540px', padding: '1.5rem', boxShadow: '0 10px 25px rgba(0,0,0,0.2)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem' }}>
              <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#0F172A', margin: 0 }}>
                {editingQuestion ? 'Edit Pertanyaan Dokter' : 'Tambah Pertanyaan Dokter'}
              </h2>
              <button
                onClick={() => {
                  setIsAddQuestionModal(false);
                  setEditingQuestion(null);
                }}
                style={{ background: 'none', border: 'none', color: '#64748B', cursor: 'pointer' }}
              >
                <XIcon size={20} />
              </button>
            </div>

            <form onSubmit={handleSaveQuestion}>
              <div style={{ marginBottom: '1rem' }}>
                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 700, color: '#334155', marginBottom: '4px' }}>
                  Teks Pertanyaan Medis *
                </label>
                <textarea
                  rows={3}
                  required
                  value={questionForm.questionText}
                  onChange={(e) => setQuestionForm({ ...questionForm, questionText: e.target.value })}
                  placeholder="Contoh: Berapa derajat keparahan retinopati diabetik pada mata saya saat ini?"
                  style={{ width: '100%', padding: '0.6rem 0.75rem', borderRadius: '8px', border: '1px solid #CBD5E1', fontSize: '0.875rem' }}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.25rem' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 700, color: '#334155', marginBottom: '4px' }}>
                    Kategori Klinis
                  </label>
                  <select
                    value={questionForm.category}
                    onChange={(e) => setQuestionForm({ ...questionForm, category: e.target.value })}
                    style={{ width: '100%', padding: '0.6rem 0.75rem', borderRadius: '8px', border: '1px solid #CBD5E1', fontSize: '0.875rem' }}
                  >
                    <option value="Pemeriksaan Retina">Pemeriksaan Retina</option>
                    <option value="Tindakan Medis & Terapi">Tindakan Medis & Terapi</option>
                    <option value="Gaya Hidup & Diet">Gaya Hidup & Diet</option>
                    <option value="Jadwal Kontrol">Jadwal Kontrol</option>
                    <option value="Obat & Terapi">Obat & Terapi</option>
                    <option value="Umum">Umum</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 700, color: '#334155', marginBottom: '4px' }}>
                    Urutan Tampil (Index)
                  </label>
                  <input
                    type="number"
                    min={1}
                    value={questionForm.orderIndex}
                    onChange={(e) => setQuestionForm({ ...questionForm, orderIndex: Number(e.target.value) })}
                    style={{ width: '100%', padding: '0.6rem 0.75rem', borderRadius: '8px', border: '1px solid #CBD5E1', fontSize: '0.875rem' }}
                  />
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
                <button
                  type="button"
                  onClick={() => {
                    setIsAddQuestionModal(false);
                    setEditingQuestion(null);
                  }}
                  style={{ padding: '0.6rem 1.25rem', background: '#F1F5F9', border: '1px solid #CBD5E1', borderRadius: '8px', fontWeight: 600, color: '#475569', cursor: 'pointer' }}
                >
                  Batal
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  style={{ padding: '0.6rem 1.5rem', background: '#0D47A1', border: 'none', borderRadius: '8px', fontWeight: 700, color: '#FFFFFF', cursor: 'pointer' }}
                >
                  {isSubmitting ? 'Menyimpan...' : 'Simpan Pertanyaan'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* =====================================================================
          MODAL: KONFIRMASI HAPUS MEAL
         ===================================================================== */}
      {deletingMeal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: '1rem' }}>
          <div style={{ background: '#FFFFFF', borderRadius: '14px', width: '100%', maxWidth: '440px', padding: '1.5rem', textAlign: 'center', boxShadow: '0 10px 25px rgba(0,0,0,0.2)' }}>
            <div style={{ width: '48px', height: '48px', borderRadius: '50%', background: '#FEE2E2', color: '#DC2626', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 1rem' }}>
              <TrashIcon size={24} />
            </div>
            <h3 style={{ fontSize: '1.15rem', fontWeight: 800, color: '#0F172A', margin: '0 0 0.5rem 0' }}>
              Hapus Menu Makanan?
            </h3>
            <p style={{ fontSize: '0.875rem', color: '#64748B', margin: '0 0 1.25rem 0' }}>
              Menu <strong>{deletingMeal.name}</strong> akan dihapus dari database master. Rencana nutrisi baru tidak akan lagi menggunakan menu ini.
            </p>
            <div style={{ display: 'flex', justifyContent: 'center', gap: '0.75rem' }}>
              <button
                onClick={() => setDeletingMeal(null)}
                style={{ padding: '0.6rem 1.25rem', background: '#F1F5F9', border: '1px solid #CBD5E1', borderRadius: '8px', fontWeight: 600, color: '#475569', cursor: 'pointer' }}
              >
                Batal
              </button>
              <button
                onClick={handleDeleteMeal}
                disabled={isSubmitting}
                style={{ padding: '0.6rem 1.5rem', background: '#DC2626', border: 'none', borderRadius: '8px', fontWeight: 700, color: '#FFFFFF', cursor: 'pointer' }}
              >
                {isSubmitting ? 'Menghapus...' : 'Ya, Hapus'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* =====================================================================
          MODAL: KONFIRMASI HAPUS QUESTION
         ===================================================================== */}
      {deletingQuestion && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: '1rem' }}>
          <div style={{ background: '#FFFFFF', borderRadius: '14px', width: '100%', maxWidth: '440px', padding: '1.5rem', textAlign: 'center', boxShadow: '0 10px 25px rgba(0,0,0,0.2)' }}>
            <div style={{ width: '48px', height: '48px', borderRadius: '50%', background: '#FEE2E2', color: '#DC2626', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 1rem' }}>
              <TrashIcon size={24} />
            </div>
            <h3 style={{ fontSize: '1.15rem', fontWeight: 800, color: '#0F172A', margin: '0 0 0.5rem 0' }}>
              Hapus Pertanyaan Dokter?
            </h3>
            <p style={{ fontSize: '0.875rem', color: '#64748B', margin: '0 0 1.25rem 0' }}>
              Pertanyaan ini akan dihapus dari panduan pra-konsultasi pasien di mobile dan portal web.
            </p>
            <div style={{ display: 'flex', justifyContent: 'center', gap: '0.75rem' }}>
              <button
                onClick={() => setDeletingQuestion(null)}
                style={{ padding: '0.6rem 1.25rem', background: '#F1F5F9', border: '1px solid #CBD5E1', borderRadius: '8px', fontWeight: 600, color: '#475569', cursor: 'pointer' }}
              >
                Batal
              </button>
              <button
                onClick={handleDeleteQuestion}
                disabled={isSubmitting}
                style={{ padding: '0.6rem 1.5rem', background: '#DC2626', border: 'none', borderRadius: '8px', fontWeight: 700, color: '#FFFFFF', cursor: 'pointer' }}
              >
                {isSubmitting ? 'Menghapus...' : 'Ya, Hapus'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

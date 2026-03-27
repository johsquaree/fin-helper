import { Router } from 'express';
import {
  createExpense,
  getExpenses,
  getExpenseById,
  updateExpense,
  deleteExpense,
  deleteExpenseByLocalId,
  updateExpenseByLocalId,
  getExpenseStats,
} from '../controllers/expenseController';
import { auth } from '../middlewares/authMiddleware';

const router = Router();

router.use(auth);

router.post('/', createExpense);
router.get('/', getExpenses);
router.get('/stats', getExpenseStats);
router.put('/by-local/:localId', updateExpenseByLocalId);
router.delete('/by-local/:localId', deleteExpenseByLocalId);
router.get('/:id', getExpenseById);
router.put('/:id', updateExpense);
router.delete('/:id', deleteExpense);

export default router;

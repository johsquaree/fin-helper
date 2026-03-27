import { Router } from 'express';
import {
  getBudgets,
  getActiveBudgets,
  getBudgetById,
  createBudget,
  updateBudget,
  deleteBudget,
} from '../controllers/budgetController';
import { auth } from '../middlewares/authMiddleware';
import {
  validateCreateBudget,
  validatePagination,
} from '../middlewares/validationMiddleware';

const router = Router();

router.use(auth);

router.get('/', validatePagination, getBudgets);
router.get('/active', getActiveBudgets);
router.get('/:id', getBudgetById);
router.post('/', validateCreateBudget, createBudget);
router.put('/:id', updateBudget);
router.delete('/:id', deleteBudget);

export default router;

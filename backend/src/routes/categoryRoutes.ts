import { Router } from 'express';
import {
  getCategories,
  getCategoryById,
  createCategory,
  updateCategory,
  deleteCategory,
} from '../controllers/categoryController';
import { auth } from '../middlewares/authMiddleware';
import {
  validateCreateCategory,
  validatePagination,
} from '../middlewares/validationMiddleware';

const router = Router();

router.use(auth);

router.get('/', validatePagination, getCategories);
router.get('/:id', getCategoryById);
router.post('/', validateCreateCategory, createCategory);
router.put('/:id', updateCategory);
router.delete('/:id', deleteCategory);

export default router;

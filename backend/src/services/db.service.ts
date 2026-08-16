import prisma from '../lib/prisma';
import dotenv from 'dotenv';
dotenv.config();

export const dbClient = prisma;
export const dbPartner = prisma;
export const db = prisma;

export { firestoreDb } from './firestore-db';

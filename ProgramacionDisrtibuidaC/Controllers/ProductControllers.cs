using Microsoft.AspNetCore.Mvc;
using ProgramacionDisrtibuidaC.Data;
using ProgramacionDisrtibuidaC.Models;
using Microsoft.EntityFrameworkCore;

namespace ProgramacionDisrtibuidaC.Controllers
{
    [Route("api/Products")]
    [ApiController]
    public class ProductControllers : ControllerBase
    {
        private readonly AppDbContext _context;
        public ProductControllers(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Product>>> GetProducts()
        {
            return await _context.Product.ToListAsync();
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateProduct(
            int id, Product product
            ) {
            if (id != product.Id)
                return BadRequest(new { message = "El ID de la ruta debe coincidir con el ID del producto." });

            product.Name = product.Name.Trim();

            var currentProduct = await _context.Product.FindAsync(id);
            if (currentProduct == null)
                return NotFound();

            if (currentProduct.Version != product.Version)
            {
                return Conflict(new
                {
                    message = "Otro cliente modificó el producto. Recárguelo e inténtelo nuevamente.",
                    currentVersion = currentProduct.Version
                });
            }

            currentProduct.Name = product.Name;
            currentProduct.Price = product.Price;
            currentProduct.Stock = product.Stock;
            currentProduct.Version++;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                return Conflict(new
                {
                    message = "Otro cliente modificó el producto. Recárguelo e inténtelo nuevamente."
                });
            }
            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProduct(int id) {
            var product = await _context.Product.FindAsync(id);
            if (product == null)
                return NotFound();

            _context.Product.Remove(product);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Product>> GetProduct(int id)
        {
            var product = await _context.Product.FindAsync(id);
            if (product == null)
                return NotFound();

            return product;
        }

        [HttpPost]
        public async Task<ActionResult<Product>> CreateProduct(Product product) {
            product.Name = product.Name.Trim();
            product.Version = 0;
            _context.Product.Add(product);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetProduct),
                new { id = product.Id }, product);
        }
    }
}
